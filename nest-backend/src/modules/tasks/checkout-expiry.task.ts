import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { isLeft } from '@/shared/core/either';
import { ExpireCheckoutGroupUseCase } from '@/modules/payments/usecases/expire-checkout-group.usecase';

@Injectable()
export class CheckoutExpiryTask {
  private readonly logger = new Logger(CheckoutExpiryTask.name);

  constructor(private readonly expireCheckoutGroupUseCase: ExpireCheckoutGroupUseCase) {}

  @Cron(CronExpression.EVERY_10_MINUTES)
  async reclaimAbandonedCheckouts() {
    const result = await this.expireCheckoutGroupUseCase.execute();
    if (isLeft(result)) {
      this.logger.error(`Failed to reclaim abandoned checkouts: ${result.value.message}`);
    }
  }
}
