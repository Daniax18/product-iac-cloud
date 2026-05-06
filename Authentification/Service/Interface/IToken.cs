using Authentification.Domain;

namespace Authentification.Service.Interface
{
    public interface IToken
    {
        string CreateToken(ApplicationUser user);
    }
}
