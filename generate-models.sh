#!/bin/sh
# Writes Models/Generated.cs: CLASSES documented classes with PROPS documented properties each.
# WebApp's OpenAPI XmlCommentGenerator emits one cache.Add(...) per documented member into
# OpenApiXmlCommentSupport.generated.cs. Record1's summary mentions "ConstraintMap", so the
# generated file passes ReSharper's word-index pre-check for custom route constraints.
set -eu
CLASSES=${1:-2000}
PROPS=${2:-10}
cd "$(dirname "$0")"
awk -v classes="$CLASSES" -v props="$PROPS" 'BEGIN {
  print "namespace Models;"
  for (c = 1; c <= classes; c++) {
    print ""
    if (c == 1)
      print "/// <summary>Record type number 1 used for sample payloads; see ConstraintMap.</summary>"
    else
      printf "/// <summary>Record type number %d used for sample payloads.</summary>\n", c
    printf "public sealed class Record%d\n{\n", c
    for (p = 1; p <= props; p++) {
      printf "    /// <summary>Gets or sets field %d of record type %d.</summary>\n", p, c
      printf "    public string? Field%d { get; set; }\n", p
    }
    print "}"
  }
}' > Models/Generated.cs
