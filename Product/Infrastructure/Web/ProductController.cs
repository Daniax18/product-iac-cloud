using Microsoft.AspNetCore.Mvc;
using Product.Application.Dto;
using Product.Application.Port.Inbound;

namespace Product.Infrastructure.Web
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductController : ControllerBase
    {
        private readonly IGetProductUseCase _getProductUseCase;
        private readonly ICreateProductUseCase _createProductUseCase;

        public ProductController(
            IGetProductUseCase getProductUseCase,
            ICreateProductUseCase createProductUseCase
        )
        {
            _getProductUseCase = getProductUseCase;
            _createProductUseCase = createProductUseCase;
        }

        [HttpGet]
        public async Task<IActionResult> GetProducts()
        {
            var result = await _getProductUseCase.ExecuteAsync();
            if (result.IsSuccess)
                return Ok(result.Value);
            return BadRequest(result.ErrorMessage);
        }

        [HttpPost]
        public async Task<IActionResult> CreateProduct([FromBody] ProductCreateDto productCreateDto)
        {
            var result = await _createProductUseCase.ExecuteAsync(productCreateDto);
            if (result.IsSuccess)
                return Ok(result.Value);
            return BadRequest(result.ErrorMessage);
        }
    }
}
