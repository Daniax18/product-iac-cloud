using Product.Application.Dto;
using Product.Domain;

namespace Product.Application.Port.Inbound
{
    public interface ICreateProductUseCase
    {
        Task<Result<MyProduct>> ExecuteAsync(ProductCreateDto productCreateDto);
    }
}
