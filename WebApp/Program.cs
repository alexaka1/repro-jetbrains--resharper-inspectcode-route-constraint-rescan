var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOpenApi();
var app = builder.Build();

app.MapGet("/", () => "Hello World!");
app.MapGet("/items/{id:int}", (int id) => id);

app.Run();
