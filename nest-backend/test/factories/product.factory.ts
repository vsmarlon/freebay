import { PrismaClient, Product, Condition, ProductStatus } from '@prisma/client';

export class ProductFactory {
  constructor(private prisma: PrismaClient) {}

  /**
   * Create a test product
   */
  async create(sellerId: string, overrides: Partial<Product> = {}): Promise<Product> {
    return this.prisma.product.create({
      data: {
        title: overrides.title || 'Test Product',
        description: overrides.description || 'This is a test product description.',
        price: overrides.price ?? 10000, // R$100.00 in cents
        condition: overrides.condition || Condition.NEW,
        status: overrides.status || ProductStatus.ACTIVE,
        sellerId,
        categoryId: overrides.categoryId || null,
        postId: overrides.postId || null,
        deletedAt: overrides.deletedAt || null,
      },
    });
  }

  /**
   * Create a product with images
   */
  async createWithImages(sellerId: string, imageUrls: string[], overrides: Partial<Product> = {}): Promise<Product> {
    const product = await this.create(sellerId, overrides);

    for (let i = 0; i < imageUrls.length; i++) {
      await this.prisma.productImage.create({
        data: {
          productId: product.id,
          url: imageUrls[i],
          order: i,
        },
      });
    }

    return this.prisma.product.findUnique({
      where: { id: product.id },
      include: { images: true },
    }) as Promise<Product>;
  }

  /**
   * Create a product with a specific price (for testing splits)
   */
  async createWithPrice(sellerId: string, priceInCents: number, overrides: Partial<Product> = {}): Promise<Product> {
    return this.create(sellerId, { ...overrides, price: priceInCents });
  }

  /**
   * Create a sold product
   */
  async createSold(sellerId: string, overrides: Partial<Product> = {}): Promise<Product> {
    return this.create(sellerId, {
      ...overrides,
      status: ProductStatus.SOLD,
    });
  }

  /**
   * Create a paused product
   */
  async createPaused(sellerId: string, overrides: Partial<Product> = {}): Promise<Product> {
    return this.create(sellerId, {
      ...overrides,
      status: ProductStatus.PAUSED,
    });
  }

  /**
   * Create a deleted product (soft delete)
   */
  async createDeleted(sellerId: string, overrides: Partial<Product> = {}): Promise<Product> {
    return this.create(sellerId, {
      ...overrides,
      status: ProductStatus.DELETED,
      deletedAt: new Date(),
    });
  }

  /**
   * Create multiple products for a seller
   */
  async createMany(sellerId: string, count: number, overrides: Partial<Product> = {}): Promise<Product[]> {
    const products: Product[] = [];
    for (let i = 0; i < count; i++) {
      products.push(
        await this.create(sellerId, {
          ...overrides,
          title: `${overrides.title || 'Test Product'} ${i + 1}`,
        }),
      );
    }
    return products;
  }
}
