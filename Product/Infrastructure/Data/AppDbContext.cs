using Microsoft.EntityFrameworkCore;
using Product.Domain;

namespace Product.Infrastructure.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }
        public DbSet<MyProduct> Products { get; set; }
    }
}
