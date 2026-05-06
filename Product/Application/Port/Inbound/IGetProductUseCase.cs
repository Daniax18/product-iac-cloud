using Product.Application.Dto;
using Product.Domain;

namespace Product.Application.Port.Inbound
{
    public interface IGetProductUseCase
    {
        Task<Result<List<MyProduct>>> ExecuteAsync();
    }
}
