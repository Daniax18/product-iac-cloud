using Authentification.Domain;
using Authentification.Service.Interface;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace Authentification.Service
{
    public class TokenService : IToken
    {
        private readonly IConfiguration _configuration;

        public TokenService(IConfiguration configuration)
        {
            _configuration = configuration;
        }
        public string CreateToken(ApplicationUser user)
        {
            var jwtSettings = _configuration.GetSection("JwtSettings");
            var secret = jwtSettings["SecretKey"] ?? throw new InvalidOperationException("JWT secret is not configured.");
            if (secret == "SET_THIS_IN_ENVIRONMENT")
            {
                throw new InvalidOperationException("JWT secret must be provided through environment variables or user secrets.");
            }
            var issuer = jwtSettings["Issuer"] ?? throw new InvalidOperationException("JWT issuer is not configured.");
            var audience = jwtSettings["Audience"] ?? throw new InvalidOperationException("JWT audience is not configured.");
            var expirationMinutes = int.TryParse(jwtSettings["ExpiryInMinutes"], out var minutes) ? minutes : 60;

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: GetClaims(user),
                expires: DateTime.UtcNow.AddMinutes(expirationMinutes),
                signingCredentials: GetSigningCredentials(secret)
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private List<Claim> GetClaims(ApplicationUser user)
        {
            var claims = new List<Claim>
            {
                new Claim("userId", user.Id.ToString()),
                new Claim("userName", user.UserName ?? string.Empty),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };
            return claims;
        }

        private SigningCredentials GetSigningCredentials(string secret)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
            return new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        }
    }
}
