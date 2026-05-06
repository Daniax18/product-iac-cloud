using Product.Application.Dto;
using Product.Application.Port.Inbound;
using Product.Application.Port.Outbound;
using Product.Domain;

namespace Product.Application.UseCase
{
    public class GetProductUseCase : IGetProductUseCase
    {
        private readonly IProductPersistence _productPersistence;
        public GetProductUseCase(IProductPersistence productPersistence)
        {
            _productPersistence = productPersistence;
        }
        public async Task<Result<List<MyProduct>>> ExecuteAsync()
        {
            try
            {
                var products = await _productPersistence.GetProductsAsync();
                return Result<List<MyProduct>>.Ok(products);
            }
            catch (Exception ex)
            {
                return Result<List<MyProduct>>.Fail(ex.Message);
            }
        }
    }
}
