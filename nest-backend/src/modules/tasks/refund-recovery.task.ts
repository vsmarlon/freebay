import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ProcessRefundUseCase } from '@/modules/payments/usecases/process-refund.usecase';

@Injectable()
export class RefundRecoveryTask {
  private readonly logger = new Logger(RefundRecoveryTask.name);

  constructor(private readonly processRefundUseCase: ProcessRefundUseCase) {}

  @Cron(CronExpression.EVERY_10_MINUTES)
  async recoverProviderConfirmedRefunds() {
    const result = await this.processRefundUseCase.recoverPendingRefunds();
    if (result.isLeft()) {
      this.logger.error(`Failed to recover pending refunds: ${result.value.message}`);
    }
  }
}
