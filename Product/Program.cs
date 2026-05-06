using Microsoft.EntityFrameworkCore;
using Product.Application.Port.Inbound;
using Product.Application.Port.Outbound;
using Product.Application.UseCase;
using Product.Infrastructure.Data;
using Product.Infrastructure.Persistence;
using System;

var builder = WebApplication.CreateBuilder(args);

var connectionString =
    //builder.Configuration.GetConnectionString("AppDb") ??
    builder.Configuration.GetConnectionString("DockerDb") ??
    //builder.Configuration.GetConnectionString("LocalDb") ??
    throw new InvalidOperationException("No database connection string is configured.");

builder.Services.AddDbContext<AppDbContext>(options =>
                options.UseNpgsql(connectionString));

builder.Services.AddControllers();

builder.Services.AddScoped<ICreateProductUseCase, CreateProductUseCase>();
builder.Services.AddScoped<IGetProductUseCase, GetProductUseCase>();
builder.Services.AddScoped<IProductPersistence, ProductRepository>();

// Add services to the container.

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

// Configure the HTTP request pipeline.

app.MapControllers();

app.Run();
