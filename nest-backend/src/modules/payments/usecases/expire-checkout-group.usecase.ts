import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ProductRepository } from '../../products/domain/repositories/product.repository';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { TransactionRepository } from '../domain/repositories/transaction.repository';
import { PaymentGroupRepository } from '../domain/repositories/payment-group.repository';

const GROUP_RACE_SKIP = 'GROUP_RACE_SKIP';

@Injectable()
export class ExpireCheckoutGroupUseCase {
  private readonly logger = new Logger(ExpireCheckoutGroupUseCase.name);

  constructor(
    private readonly paymentGroupRepo: PaymentGroupRepository,
    private readonly transactionRepo: TransactionRepository,
    private readonly productRepo: ProductRepository,
    private readonly orderRepo: OrderRepository,
    private readonly prisma: PrismaService,
  ) {}

  async execute(): Promise<Either<AppError, void>> {
    const now = new Date();
    let groupsExpired = 0;
    let ordersReclaimed = 0;

    const groupIdsResult = await this.paymentGroupRepo.findExpiredGroupIds(now);
    if (isLeft(groupIdsResult)) return left(groupIdsResult.value);

    for (const groupId of groupIdsResult.value) {
      const groupResult = await this.paymentGroupRepo.findById(groupId);
      if (isLeft(groupResult) || !groupResult.value) {
        this.logger.error(`Failed to load expired payment group ${groupId}`);
        continue;
      }

      const group = groupResult.value;
      try {
        const reclaimed = await this.prisma.$transaction(async (tx) => {
          const claimed = await this.paymentGroupRepo.markTerminal(group.id, 'EXPIRED', tx);
          if (claimed === 0) throw new Error(GROUP_RACE_SKIP);

          let count = 0;
          for (const order of group.orders) {
            const failed = await this.transactionRepo.markAsFailed(order.transactionId, tx);
            if (isLeft(failed)) throw new Error(failed.value.message);
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
          `Failed to expire payment group ${group.id}: ${(error as Error).message}`,
          error instanceof Error ? error.stack : undefined,
        );
      }
    }

    const soloResult = await this.transactionRepo.findExpiredPending(now);
    if (isLeft(soloResult)) return left(soloResult.value);

    for (const transaction of soloResult.value) {
      try {
        const reclaimed = await this.prisma.$transaction(async (tx) => {
          const failed = await this.transactionRepo.markAsFailed(transaction.id, tx);
          if (isLeft(failed)) throw new Error(failed.value.message);
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
          `Failed to expire transaction ${transaction.id}: ${(error as Error).message}`,
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
