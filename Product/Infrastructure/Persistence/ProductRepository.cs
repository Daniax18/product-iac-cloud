using Microsoft.EntityFrameworkCore;
using Product.Application.Port.Outbound;
using Product.Domain;
using Product.Infrastructure.Data;

namespace Product.Infrastructure.Persistence
{
    public class ProductRepository : IProductPersistence
    {
        private readonly AppDbContext _context;
        public ProductRepository(AppDbContext context)
        {
            _context = context;
        }   

        public async Task<MyProduct> CreateProductAsync(MyProduct product)
        {
            await _context.Products.AddAsync(product);
            await _context.SaveChangesAsync();
            return product;
        }

        public async Task<List<MyProduct>> GetProductsAsync()
        {
            return await _context.Products.ToListAsync();
        }
    }
}
