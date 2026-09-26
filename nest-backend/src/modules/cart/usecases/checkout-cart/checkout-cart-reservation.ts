import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { CHECKOUT_EXPIRY_MILLISECONDS } from '@/modules/payments/payment.constants';
import { CartDatabaseRepository } from "../../data/repositories/cart-database.repository";
import { PaymentGroupDatabaseRepository } from "@/modules/payments/data/repositories/payment-group-database.repository";
import { PlannedCartItem } from "./checkout-cart.types";

export class CheckoutCartReservation {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cartRepository: CartDatabaseRepository,
    private readonly paymentGroupRepository: PaymentGroupDatabaseRepository,
  ) {}

  async reserve(
    userId: string,
    idempotencyKey: string,
    totalAmount: number,
    planned: PlannedCartItem[],
  ): Promise<{ groupId: string; reserved: Array<{ orderId: string; productId: string }> }> {
    return this.prisma.$transaction(async (tx) => {
      const reserved: Array<{ orderId: string; productId: string }> = [];
      for (const item of planned) {
        const order = await this.cartRepository.reserveAndCreateOrder(item, tx);
        reserved.push({ orderId: order.id, productId: item.productId });
      }
      const group = await this.paymentGroupRepository.create({
        buyerId: userId,
        amount: totalAmount,
        currency: "brl",
        idempotencyKey,
        expiresAt: new Date(Date.now() + CHECKOUT_EXPIRY_MILLISECONDS),
        orders: reserved.map((entry, index) => ({
          orderId: entry.orderId,
          amount: planned[index].amount,
          platformFee: planned[index].platformFee,
          sellerAmount: planned[index].sellerAmount,
        })),
      }, tx);
      return { groupId: group.id, reserved };
    });
  }
}
