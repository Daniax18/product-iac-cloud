using Product.Application.Dto;
using Product.Application.Port.Inbound;
using Product.Application.Port.Outbound;
using Product.Domain;

namespace Product.Application.UseCase
{
    public class CreateProductUseCase : ICreateProductUseCase
    {
        private readonly IProductPersistence _productPersistence;
        
        public CreateProductUseCase(IProductPersistence productPersistence)
        {
            _productPersistence = productPersistence;
        }
        public async Task<Result<MyProduct>> ExecuteAsync(ProductCreateDto productCreateDto)
        {
            try
            {
                var product = await _productPersistence.CreateProductAsync(
                    new MyProduct(productCreateDto.Name, productCreateDto.Price)
                );

                return Result<MyProduct>.Ok(product);
            }
            catch (Exception ex)
            {
                return Result<MyProduct>.Fail(ex.Message);
            }
        }
    }
}
