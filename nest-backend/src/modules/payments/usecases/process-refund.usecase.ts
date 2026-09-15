import { Injectable, Logger } from "@nestjs/common";
import Stripe from "stripe";
import { OrderStatus } from "@prisma/client";
import { Either, left, right } from "@/shared/core/either";
import {
  AppError,
  DatabaseError,
  InvalidOrderStateError,
} from "@/shared/core/errors";
import { TransactionDatabaseRepository } from "../data/repositories/transaction-database.repository";
import { PrismaOrderRepository } from "../../orders/data/repositories/order-database.repository";
import { SellerPayoutService } from "../services/seller-payout.service";

export function isFullRefund(
  charge: Pick<Stripe.Charge, "refunded" | "amount" | "amount_refunded">,
): boolean {
  const hasValidAmounts =
    Number.isInteger(charge.amount) &&
    charge.amount > 0 &&
    Number.isInteger(charge.amount_refunded) &&
    charge.amount_refunded > 0;

  return (
    charge.refunded === true ||
    (hasValidAmounts && charge.amount_refunded === charge.amount)
  );
}

@Injectable()
export class ProcessRefundUseCase {
  private readonly logger = new Logger(ProcessRefundUseCase.name);

  constructor(
    private readonly transactionRepo: TransactionDatabaseRepository,
    private readonly orderRepo: PrismaOrderRepository,
    private readonly payoutService: SellerPayoutService,
  ) {}

  async execute(
    chargeId: string,
    fullRefund = true,
  ): Promise<Either<AppError, void>> {
    if (!fullRefund) return right(undefined);

    const found = await this.transactionRepo.findByChargeId(chargeId);
    if (found.isLeft()) return left(found.value);
    if (!found.value) return right(undefined);

    const transaction = found.value;
    const order = transaction.order;

    if (order.status === "CANCELLED" || order.escrowStatus === "REFUNDED") {
      return right(undefined);
    }

    const refundableStatuses: OrderStatus[] = [
      OrderStatus.CONFIRMED,
      OrderStatus.SHIPPED,
      OrderStatus.DELIVERED,
      OrderStatus.COMPLETED,
    ];
    if (!refundableStatuses.includes(order.status)) {
      return left(
        new InvalidOrderStateError(refundableStatuses.join("/"), order.status),
      );
    }

    const escrowStatus =
      order.escrowStatus === "RELEASED"
        ? "RELEASED"
        : order.escrowStatus === "HELD"
          ? "HELD"
          : undefined;
    if (!escrowStatus) {
      return left(
        new InvalidOrderStateError("HELD/RELEASED", order.escrowStatus),
      );
    }

    const reversed = await this.payoutService.reverseForOrder(order.id);
    if (reversed.isLeft()) return left(reversed.value);

    const refunded = await this.orderRepo.refundOrder({
      orderId: order.id,
      productId: order.productId,
      buyerId: order.buyerId,
      amount: order.amount,
      status: order.status,
      escrowStatus,
      orderQuantity: order.quantity,
      sellerId: order.sellerId,
      sellerAmount: order.sellerAmount,
      transferId: transaction.transferId,
    });
    if (refunded.isLeft())
      return left(new DatabaseError("Failed to refund order"));

    this.logger.log(
      `Refund processed for order ${order.id} (charge ${chargeId})`,
    );
    return right(undefined);
  }
}
