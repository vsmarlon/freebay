import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';
import { ReversalState, TransferDeliveryState } from '@prisma/client';
import { MINUTES_IN_MILLISECONDS, TRANSFER_PROCESSING_LEASE_MINUTES } from './task.constants';

@Injectable()
export class TransferReconciliationTask {
  private readonly logger = new Logger(TransferReconciliationTask.name);

  constructor(
    private readonly transactions: TransactionDatabaseRepository,
    private readonly payouts: SellerPayoutService,
  ) {}

  @Cron(CronExpression.EVERY_10_MINUTES)
  async reconcile() {
    const cutoff = new Date(
      Date.now() - TRANSFER_PROCESSING_LEASE_MINUTES * MINUTES_IN_MILLISECONDS,
    );
    await this.transactions.reclaimStaleTransfer(cutoff);
    await this.transactions.reclaimStaleReversal(cutoff);
    const failures = await this.transactions.findTransferFailures();
    if (failures.isLeft()) {
      this.logger.error(failures.value.message);
      return;
    }
    for (const transaction of failures.value.items) {
      if (
        transaction.transferState === TransferDeliveryState.RETRYABLE ||
        transaction.transferState === TransferDeliveryState.PROCESSING
      ) {
        await this.payouts.payoutForOrder(transaction.orderId);
      }
      if (
        transaction.reversalState === ReversalState.RETRYABLE ||
        transaction.reversalState === ReversalState.PROCESSING
      ) {
        await this.payouts.reverseForOrder(transaction.orderId);
      }
    }
  }
}
