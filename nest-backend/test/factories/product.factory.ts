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
        price: overrides.price ?? 10000,
        quantity: overrides.quantity ?? 1,
        soldCount: overrides.soldCount ?? 0,
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

}
