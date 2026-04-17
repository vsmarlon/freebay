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
   * Create a confirmed order
   */
  async createConfirmed(buyerId: string, sellerId: string, productId: string): Promise<Order> {
    return this.create(buyerId, sellerId, productId, {
      status: OrderStatus.CONFIRMED,
    });
  }

  /**
   * Create a shipped order
   */
  async createShipped(buyerId: string, sellerId: string, productId: string): Promise<Order> {
    return this.create(buyerId, sellerId, productId, {
      status: OrderStatus.SHIPPED,
    });
  }

  /**
   * Create a delivered order
   */
  async createDelivered(buyerId: string, sellerId: string, productId: string): Promise<Order> {
    return this.create(buyerId, sellerId, productId, {
      status: OrderStatus.DELIVERED,
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

  /**
   * Create a cancelled order
   */
  async createCancelled(buyerId: string, sellerId: string, productId: string): Promise<Order> {
    return this.create(buyerId, sellerId, productId, {
      status: OrderStatus.CANCELLED,
      escrowStatus: EscrowStatus.REFUNDED,
    });
  }

  /**
   * Create a disputed order
   */
  async createDisputed(buyerId: string, sellerId: string, productId: string): Promise<Order> {
    return this.create(buyerId, sellerId, productId, {
      status: OrderStatus.DISPUTED,
    });
  }

  /**
   * Create order with transaction
   */
  async createWithTransaction(
    buyerId: string,
    sellerId: string,
    productId: string,
    transactionStatus: string = 'PAID',
  ): Promise<Order> {
    const order = await this.create(buyerId, sellerId, productId);

    await this.prisma.transaction.create({
      data: {
        orderId: order.id,
        amount: order.amount,
        platformFee: order.platformFee,
        sellerAmount: order.sellerAmount,
        paymentMethod: 'PIX',
        provider: 'PAGARME',
        status: transactionStatus as any,
        idempotencyKey: `test-${Date.now()}-${Math.random().toString(36).substring(7)}`,
        paidAt: transactionStatus === 'PAID' ? new Date() : null,
      },
    });

    return this.prisma.order.findUnique({
      where: { id: order.id },
      include: { transaction: true },
    }) as Promise<Order>;
  }
}
