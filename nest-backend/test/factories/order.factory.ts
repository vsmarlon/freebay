import { PrismaClient, Order, OrderStatus, EscrowStatus } from '@prisma/client';

export class OrderFactory {
  private readonly PLATFORM_FEE_PERCENTAGE = 0.1; // 10%

  constructor(private prisma: PrismaClient) {}

  /**
   * Create a test order with automatic split calculation
   */
  async create(
    buyerId: string,
    sellerId: string,
    productId: string,
    overrides: Partial<Order> = {},
  ): Promise<Order> {
    // Get product to calculate splits
    const product = await this.prisma.product.findUnique({
      where: { id: productId },
    });

    if (!product) {
      throw new Error(`Product ${productId} not found`);
    }

    const amount = product.price;
    const platformFee = Math.floor(amount * this.PLATFORM_FEE_PERCENTAGE);
    const sellerAmount = amount - platformFee;

    return this.prisma.order.create({
      data: {
        buyerId,
        sellerId,
        productId,
        amount,
        platformFee,
        sellerAmount,
        status: overrides.status || OrderStatus.PENDING,
        escrowStatus: overrides.escrowStatus || EscrowStatus.HELD,
        meetingScheduledAt: overrides.meetingScheduledAt || null,
        deliveryConfirmedAt: overrides.deliveryConfirmedAt || null,
      },
    });
  }

  /**
   * Create order with specific amounts (for testing edge cases)
   */
  async createWithAmounts(
    buyerId: string,
    sellerId: string,
    productId: string,
    amount: number,
    platformFee: number,
    sellerAmount: number,
    overrides: Partial<Order> = {},
  ): Promise<Order> {
    return this.prisma.order.create({
      data: {
        buyerId,
        sellerId,
        productId,
        amount,
        platformFee,
        sellerAmount,
        status: overrides.status || OrderStatus.PENDING,
        escrowStatus: overrides.escrowStatus || EscrowStatus.HELD,
        meetingScheduledAt: overrides.meetingScheduledAt || null,
        deliveryConfirmedAt: overrides.deliveryConfirmedAt || null,
      },
    });
  }

  /**
   * Create a completed order with released escrow
   */
  async createCompleted(buyerId: string, sellerId: string, productId: string): Promise<Order> {
    return this.create(buyerId, sellerId, productId, {
      status: OrderStatus.COMPLETED,
      escrowStatus: EscrowStatus.RELEASED,
      deliveryConfirmedAt: new Date(),
    });
  }

}
