import { createHash } from "node:crypto";
import { PaymentGroupStatus, ProductStatus } from '@prisma/client';
import { AppError, BadRequestError } from "@/shared/core/errors";
import { Either, left, right } from "@/shared/core/either";
import { CartDatabaseRepository } from "../../data/repositories/cart-database.repository";
import { PaymentGroupDatabaseRepository } from "@/modules/payments/data/repositories/payment-group-database.repository";
import { PaymentGroupSnapshot } from "@/modules/payments/types/payment-group.types";
import { splitAmount } from "@/shared/core/platform-fee";
import { CheckoutCartInput, CheckoutCartOutput, CheckoutMode } from "../../dtos/cart.dto";
import { PlannedCartItem } from "./checkout-cart.types";

export type CheckoutPlan = {
  cpf: string | null;
  planned: PlannedCartItem[];
  totalAmount: number;
  idempotencyKey: string;
};

export class CheckoutCartPlanner {
  constructor(
    private readonly cartRepository: CartDatabaseRepository,
    private readonly paymentGroupRepository: PaymentGroupDatabaseRepository,
  ) {}

  async plan(input: CheckoutCartInput, mode: CheckoutMode): Promise<Either<AppError, CheckoutPlan>> {
    const cpfResult = await this.cartRepository.findUserCpf(input.userId);
    if (cpfResult.isLeft()) return left(cpfResult.value);
    if (mode === "session" && !cpfResult.value) {
      return left(new BadRequestError("Adicione seu CPF no perfil antes de realizar uma compra"));
    }
    const cartResult = await this.cartRepository.getUserCart(input.userId);
    if (cartResult.isLeft()) return left(cartResult.value);
    if (cartResult.value.length === 0) return left(new BadRequestError("Carrinho vazio"));

    const planned: PlannedCartItem[] = [];
    for (const item of cartResult.value) {
      if (item.product.sellerId === input.userId) {
        return left(new BadRequestError("Você não pode comprar seu próprio produto"));
      }
      if (item.product.status !== ProductStatus.ACTIVE) {
        return left(new BadRequestError("Um ou mais produtos do carrinho não estão disponíveis"));
      }
      const availableStock = Math.max(item.product.quantity - item.product.soldCount, 0);
      if (item.quantity < 1 || item.quantity > availableStock) {
        return left(new BadRequestError(`Estoque insuficiente para ${item.product.title}`));
      }
      const amount = item.product.price * item.quantity;
      const { platformFee, sellerAmount } = splitAmount(amount);
      planned.push({
        userId: input.userId,
        sellerId: item.product.sellerId,
        productId: item.productId,
        productTitle: item.product.title,
        quantity: item.quantity,
        amount,
        platformFee,
        sellerAmount,
      });
    }

    const totalAmount = planned.reduce((sum, item) => sum + item.amount, 0);
    return right({
      cpf: cpfResult.value,
      planned,
      totalAmount,
      idempotencyKey: this.buildIdempotencyKey(input.userId, planned, mode),
    });
  }

  async findReusable(idempotencyKey: string): Promise<Either<AppError, PaymentGroupSnapshot | null>> {
    return this.paymentGroupRepository.findByIdempotencyKey(idempotencyKey);
  }

  isReusable(group: PaymentGroupSnapshot): boolean {
    return group.status === PaymentGroupStatus.PENDING && group.expiresAt !== null &&
      group.expiresAt.getTime() > Date.now() && Boolean(group.checkoutUrl || group.clientSecret);
  }

  toOutput(group: PaymentGroupSnapshot): CheckoutCartOutput {
    const items = group.orders.map((order) => ({
      orderId: order.orderId,
      productId: order.productId,
      productTitle: order.productTitle,
      quantity: order.quantity,
      amount: order.amount,
    }));
    return {
      paymentGroupId: group.id,
      items,
      totalOrders: items.length,
      totalAmount: group.amount,
      checkoutUrl: group.checkoutUrl,
      paymentIntentClientSecret: group.clientSecret,
      expiresAt: group.expiresAt,
    };
  }

  private buildIdempotencyKey(userId: string, planned: PlannedCartItem[], mode: CheckoutMode): string {
    const fingerprint = planned
      .map((item) => `${item.productId}:${item.quantity}:${item.amount}`)
      .sort()
      .join("|");
    const digest = createHash("sha256").update(fingerprint).digest("hex").slice(0, 32);
    return `cart:${userId}:${mode}:${digest}`;
  }
}
