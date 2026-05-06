using Authentification.Domain;
using Authentification.Service.Dto;
using Authentification.Service.Dto.Login;
using Authentification.Service.Dto.Register;
using Authentification.Service.Interface;
using Microsoft.AspNetCore.Identity;

namespace Authentification.Service
{
    public class UserService : IUser
    {

        private readonly UserManager<ApplicationUser> _userManager;
        private readonly SignInManager<ApplicationUser> _signInManager;
        private readonly IToken _tokenService;

        public UserService(UserManager<ApplicationUser> userManager, SignInManager<ApplicationUser> signInManager, IToken tokenService)
        {
            _userManager = userManager;
            _signInManager = signInManager;
            _tokenService = tokenService;
        }

        public async Task<Result<LoginResponseDto>> LoginAsync(LoginRequestDto request)
        {
            var user = await _userManager.FindByEmailAsync(request.Email);

            if (user == null)
                return Result<LoginResponseDto>.Fail("Invalid credentials");

            var result = await _signInManager.CheckPasswordSignInAsync(user, request.Password, false);
            if (!result.Succeeded) return Result<LoginResponseDto>.Fail("Invalid credentials");

            var token = _tokenService.CreateToken(user);

            var response = new LoginResponseDto
            {
                Token = token,
                UserId = user.Id,
                UserName = user.UserName ?? string.Empty,
                Email = user.Email ?? string.Empty
            };

            return Result<LoginResponseDto>.Ok(response);
        }

        public async Task<Result<ApplicationUser>> RegisterAsync(RegisterRequestDto request)
        {
            var checkUser = await _userManager.FindByEmailAsync(request.Email);
            if (checkUser != null)
                return Result<ApplicationUser>.Fail("Email already in use");

            var user = new ApplicationUser
            {
                UserName = request.UserName,
                Email = request.Email
            };

            var result = await _userManager.CreateAsync(user, request.Password);

            if (!result.Succeeded)
                return Result<ApplicationUser>.Fail(string.Join(", ", result.Errors.Select(e => e.Description)));

            return Result<ApplicationUser>.Ok(user);
        }
    }
}
