# InspectCode: route constraint lookup re-walks a large generated file

Repro for ReSharper Command Line Tools (InspectCode) 2026.2.3.1.

When a project has no custom route constraints, the provider behind `RouteConstraintsCache` never
records its empty result. Each `RouteConstraintsCache` miss for the module therefore requeues every
module file, and each file that passes the `ConstraintMap` word-index check goes through
`AspNetCoreStartupFileAnalyzer.GetCustomConstraints`. That method resolves every invocation named `Add`
or `TryAdd` before checking its arguments. Here the candidate is the OpenAPI XML-comment source
generator output, `OpenApiXmlCommentSupport.generated.cs` (3.6 MB, about 22,000 `cache.Add(...)`
calls). When two route files miss the cache at the same time, the file is walked twice, one walk
after the other.

## Contents

- `WebApp`: `dotnet new web` (commit 1) plus:
  - `Microsoft.AspNetCore.OpenApi` + `AddOpenApi()` + `GenerateDocumentationFile`
  - `app.MapGet("/items/{id:int}", ...)` in `Program.cs`
  - `Components/ItemPage.razor` with `@page "/p/{Id:int}"`
  - no custom route constraints
- `Models`: class library with 2,000 documented classes (`generate-models.sh`). Its XML docs feed the
  generator in `WebApp`. `Record1`'s summary contains the word `ConstraintMap`, so the generated file
  passes the word-index pre-check (`AspNetCoreStartupConfigurationProvider.NeedToProcess`).
- `dotnet-tools.json`: pins `JetBrains.ReSharper.GlobalTools` 2026.2.3.1.
- `workaround.DotSettings`: disables the route template language injection.

## Run

```sh
docker run --rm --cpus=4 --memory=8g -v "$PWD":/src:ro mcr.microsoft.com/dotnet/sdk:10.0.403-noble@sha256:de4fe90a98845d75910b9769662465c84de1a934665c431279d1382b2bddc02b bash -c \
  'cp -r /src /tmp/w && cd /tmp/w && dotnet tool restore && time dotnet jb inspectcode Repro.slnx --output=/tmp/report.sarif --verbosity=VERBOSE' \
  2>&1 | perl -MPOSIX -ne '$|=1; print strftime("%H:%M:%S ", localtime), $_' > inspect.log
grep -E 'Daemon process [0-9]+ (started|finished) on file .*(f:Program\.cs|ItemPage\.razor/z:2-0)' inspect.log
tail -3 inspect.log   # real = InspectCode wall time, including its build
```

Add `--settings=workaround.DotSettings` to the `inspectcode` command to run with the workaround.

Runtime 10.0.13 instead of 10.0.14: use
`mcr.microsoft.com/dotnet/sdk:10.0.402-noble@sha256:747cbade5bfd918a175ac32f8f1d931edec2c7d0d5397a3de72eaef1ac1f66d2`.

Smaller generated file (same code, 1 documented class):

```sh
./generate-models.sh 1 10
```
