using Product.Application.Dto;
using Product.Domain;

namespace Product.Application.Port.Outbound
{
    public interface IProductPersistence
    {
        Task<List<MyProduct>> GetProductsAsync();
        Task<MyProduct> CreateProductAsync(MyProduct product);
    }
}
