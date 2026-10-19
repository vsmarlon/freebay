import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AccountLifecycleDatabaseRepository } from '@/modules/users/data/repositories/account-lifecycle-database.repository';
import { ACCOUNT_DELETION_GRACE_DAYS } from '@/modules/users/usecases/request-account-deletion.usecase';

@Injectable()
export class AccountDeletionTask {
  private readonly logger = new Logger(AccountDeletionTask.name);

  constructor(private readonly accountLifecycleRepository: AccountLifecycleDatabaseRepository) {}

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async purgeExpiredDeletionRequests() {
    const purgeBefore = new Date();
    purgeBefore.setDate(purgeBefore.getDate() - ACCOUNT_DELETION_GRACE_DAYS);

    const candidatesResult = await this.accountLifecycleRepository.findPurgeCandidates(purgeBefore);
    if (candidatesResult.isLeft()) {
      this.logger.error(`Failed to list accounts due for purge: ${candidatesResult.value.message}`);
      return;
    }

    for (const candidate of candidatesResult.value) {
      const purgeResult = await this.accountLifecycleRepository.purge(candidate.id, purgeBefore, new Date());
      if (purgeResult.isLeft()) {
        this.logger.error(`Failed to purge account ${candidate.id}: ${purgeResult.value.message}`);
        continue;
      }

      if (purgeResult.value === 'pending-media') {
        this.logger.warn(`Personal purge for account ${candidate.id} remains pending media cleanup; storage ownership/reference safety is unverified`);
      } else if (purgeResult.value === 'pending-review') {
        this.logger.warn(`Personal purge for account ${candidate.id} remains pending report/moderation retention review`);
      } else if (purgeResult.value === 'pending-verification') {
        this.logger.warn(`Personal purge for account ${candidate.id} has no completion evidence; manual verification is required`);
      } else if (purgeResult.value === 'completed') {
        this.logger.log(`Approved personal purge scope completed for account ${candidate.id}`);
      }
    }
  }
}
