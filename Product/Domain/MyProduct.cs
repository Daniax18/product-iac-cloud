namespace Product.Domain
{
    public class MyProduct
    {
        public string Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }

        public MyProduct()
        {
        }

        public MyProduct(string name, decimal price)
        {
            Id = Guid.NewGuid().ToString();
            Name = name;
            Price = price;
        }
    }
}
