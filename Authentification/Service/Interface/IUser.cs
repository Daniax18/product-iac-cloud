using Authentification.Domain;
using Authentification.Service.Dto;
using Authentification.Service.Dto.Login;
using Authentification.Service.Dto.Register;

namespace Authentification.Service.Interface
{
    public interface IUser
    {
        Task<Result<LoginResponseDto>> LoginAsync(LoginRequestDto request);

        Task<Result<ApplicationUser>> RegisterAsync(RegisterRequestDto request);
    }
}
