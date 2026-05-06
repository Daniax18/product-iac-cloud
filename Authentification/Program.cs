using Authentification.Data;
using Authentification.Domain;
using Authentification.Service;
using Authentification.Service.Interface;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

var connectionString =
    // builder.Configuration.GetConnectionString("AppDb") ??
    builder.Configuration.GetConnectionString("DockerDb") ??
    // builder.Configuration.GetConnectionString("LocalDb") ??
    throw new InvalidOperationException("No database connection string is configured.");

builder.Services.AddDbContext<AppDbContext>(options =>
                options.UseNpgsql(connectionString));

builder.Services.AddControllers();

// =============================
// CONFIGURATION JWT
// (Authentification par token)
// =============================
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
// R�cup�re la cl� secr�te pour signer les tokens
var secretKey = jwtSettings["SecretKey"] ?? throw new InvalidOperationException("JwtSettings:SecretKey is not configured.");

if (secretKey == "SET_THIS_IN_ENVIRONMENT")
{
    throw new InvalidOperationException("JwtSettings:SecretKey must be provided through environment variables or user secrets.");
}

builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
    .AddEntityFrameworkStores<AppDbContext>()
    .AddDefaultTokenProviders();

builder.Services.AddAuthentication(options =>
{
    // D�finit JWT comme m�thode d�authentification par d�faut
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
// Configuration du middleware JWT
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,                                                                  // V�rifie qui a �mis le token
        ValidateAudience = true,                                                                // V�rifie � qui le token est destin�
        ValidateLifetime = true,                                                                // V�rifie expiration
        ValidateIssuerSigningKey = true,                                                        // V�rifie signature du token
        ValidIssuer = jwtSettings["Issuer"],                                                    // Doit correspondre au token
        ValidAudience = jwtSettings["Audience"],                                                // Doit correspondre au token
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),         // Cl� utilis�e pour signer et valider le token
        ClockSkew = TimeSpan.Zero                                                               // Pas de tol�rance sur l'expiration (plus strict)
    };
});

builder.Services.AddScoped<IToken, TokenService>();
builder.Services.AddScoped<IUser, UserService>();

// Add services to the container.
var app = builder.Build();

// 5. Migration AU D�MARRAGE (avant app.Run)
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
}

// Configure the HTTP request pipeline.

app.UseHttpsRedirection();

app.UseAuthentication();        // Active l�authentification (lecture du token JWT)
//app.UseAuthorization();         // Active l�autorisation ([Authorize])

app.MapControllers();           // Mappe les routes des controllers

app.Run();
