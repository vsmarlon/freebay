import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ProductDatabaseRepository } from '../../products/data/repositories/product-database.repository';
import { OrderDatabaseRepository } from '../../orders/data/repositories/order-database.repository';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { PaymentGroupDatabaseRepository } from '../data/repositories/payment-group-database.repository';
import { StripeProvider } from '../providers/stripe-provider';

const GROUP_RACE_SKIP = 'GROUP_RACE_SKIP';
// Ceiling: an unpaid order older than this loses its product reservation. The window
// covers a checkout started right after order creation; a payment that settles later is
// refused by the webhook because the order is no longer PENDING.
const STALE_UNPAID_ORDER_CUTOFF_MS = 30 * 60 * 1000;

@Injectable()
export class ExpireCheckoutGroupUseCase {
  private readonly logger = new Logger(ExpireCheckoutGroupUseCase.name);

  constructor(
    private readonly paymentGroupRepo: PaymentGroupDatabaseRepository,
    private readonly transactionRepo: TransactionDatabaseRepository,
    private readonly productRepo: ProductDatabaseRepository,
    private readonly orderRepo: OrderDatabaseRepository,
    private readonly prisma: PrismaService,
    private readonly stripe: StripeProvider,
  ) {}

  async execute(): Promise<Either<AppError, void>> {
    const now = new Date();
    let groupsExpired = 0;
    let ordersReclaimed = 0;

    const groupIdsResult = await this.paymentGroupRepo.findExpiredGroupIds(now);
    if (groupIdsResult.isLeft()) return left(groupIdsResult.value);

    for (const groupId of groupIdsResult.value) {
      const groupResult = await this.paymentGroupRepo.findById(groupId);
      if (groupResult.isLeft() || !groupResult.value) {
        this.logger.error(`Failed to load expired payment group ${groupId}`);
        continue;
      }

      const group = groupResult.value;
      if (!group.stripeSessionId && !group.stripePaymentIntentId) {
        this.logger.warn(`Payment group ${group.id} has no provider identity; inventory remains held`);
        continue;
      }
      const providerCancellation = await this.stripe.cancelPendingPayment({
        stripeSessionId: group.stripeSessionId ?? undefined,
        stripePaymentIntentId: group.stripePaymentIntentId ?? undefined,
        idempotencyKey: `checkout-expiry-${group.id}`,
      });
      if (providerCancellation.isLeft()) {
        this.logger.warn(`Payment group ${group.id} remains held pending provider reconciliation`);
        continue;
      }
      try {
        const reclaimed = await this.prisma.$transaction(async (tx) => {
          const claimed = await this.paymentGroupRepo.markTerminal(group.id, 'EXPIRED', tx);
          if (claimed === 0) throw new Error(GROUP_RACE_SKIP);

          let count = 0;
          for (const order of group.orders) {
            const failed = await this.transactionRepo.markAsFailed(order.transactionId, tx);
            if (failed.isLeft()) throw new Error(failed.value.message);
            if (failed.value.count === 0) continue;

            await this.orderRepo.cancel(order.orderId, tx);
            await this.productRepo.restoreInventoryOnExpiry(order.productId, order.quantity, tx);
            count += 1;
          }
          return count;
        });

        groupsExpired += 1;
        ordersReclaimed += reclaimed;
      } catch (error) {
        if (error instanceof Error && error.message === GROUP_RACE_SKIP) continue;
        this.logger.error(
          `Failed to expire payment group ${group.id}: ${error instanceof Error ? error.message : String(error)}`,
          error instanceof Error ? error.stack : undefined,
        );
      }
    }

    const soloResult = await this.transactionRepo.findExpiredPending(now);
    if (soloResult.isLeft()) return left(soloResult.value);

    for (const transaction of soloResult.value) {
      if (!transaction.externalId) {
        this.logger.warn(`Transaction ${transaction.id} has no provider identity; inventory remains held`);
        continue;
      }
      const providerCancellation = await this.stripe.cancelPendingPayment({
        stripeSessionId: transaction.externalId.startsWith('cs_') ? transaction.externalId : undefined,
        stripePaymentIntentId: transaction.externalId.startsWith('pi_') ? transaction.externalId : undefined,
        idempotencyKey: `checkout-expiry-${transaction.idempotencyKey}`,
      });
      if (providerCancellation.isLeft()) {
        this.logger.warn(`Transaction ${transaction.id} remains held pending provider reconciliation`);
        continue;
      }
      try {
        const reclaimed = await this.prisma.$transaction(async (tx) => {
          const failed = await this.transactionRepo.markAsFailed(transaction.id, tx);
          if (failed.isLeft()) throw new Error(failed.value.message);
          if (failed.value.count === 0) return 0;

          await this.orderRepo.cancel(transaction.orderId, tx);
          await this.productRepo.restoreInventoryOnExpiry(
            transaction.productId,
            transaction.quantity,
            tx,
          );
          return 1;
        });

        ordersReclaimed += reclaimed;
      } catch (error) {
        this.logger.error(
          `Failed to expire transaction ${transaction.id}: ${error instanceof Error ? error.message : String(error)}`,
          error instanceof Error ? error.stack : undefined,
        );
      }
    }

    const staleResult = await this.orderRepo.findStaleUnpaidOrders(
      new Date(now.getTime() - STALE_UNPAID_ORDER_CUTOFF_MS),
    );
    if (staleResult.isLeft()) return left(staleResult.value);

    for (const order of staleResult.value) {
      try {
        const reclaimed = await this.prisma.$transaction(async (tx) => {
          const claimed = await this.orderRepo.claimCheckoutAbandoned(order.id, tx);
          if (claimed.isLeft()) throw new Error(claimed.value.message);
          if (!claimed.value) return 0;

          const restored = await this.productRepo.restoreInventoryOnExpiry(
            order.productId,
            order.quantity,
            tx,
          );
          if (restored.isLeft()) throw new Error(restored.value.message);
          return 1;
        });

        ordersReclaimed += reclaimed;
      } catch (error) {
        this.logger.error(
          `Failed to reclaim abandoned order ${order.id}: ${error instanceof Error ? error.message : String(error)}`,
          error instanceof Error ? error.stack : undefined,
        );
      }
    }

    if (groupsExpired > 0 || ordersReclaimed > 0) {
      this.logger.log(
        `Reclaimed ${ordersReclaimed} abandoned order(s) across ${groupsExpired} expired payment group(s)`,
      );
    }

    return right(undefined);
  }
}
