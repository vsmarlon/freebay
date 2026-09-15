import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';

@Injectable()
export class TransferReconciliationTask {
  private readonly logger = new Logger(TransferReconciliationTask.name);

  constructor(
    private readonly transactions: TransactionDatabaseRepository,
    private readonly payouts: SellerPayoutService,
  ) {}

  @Cron(CronExpression.EVERY_10_MINUTES)
  async reconcile() {
    const cutoff = new Date(Date.now() - 15 * 60 * 1000);
    await this.transactions.reclaimStaleTransfer(cutoff);
    await this.transactions.reclaimStaleReversal(cutoff);
    const failures = await this.transactions.findTransferFailures();
    if (failures.isLeft()) {
      this.logger.error(failures.value.message);
      return;
    }
    for (const transaction of failures.value.items) {
      if (transaction.transferState === 'RETRYABLE' || transaction.transferState === 'PROCESSING') {
        await this.payouts.payoutForOrder(transaction.orderId);
      }
      if (transaction.reversalState === 'RETRYABLE' || transaction.reversalState === 'PROCESSING') {
        await this.payouts.reverseForOrder(transaction.orderId);
      }
    }
  }
}
