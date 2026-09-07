import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { isLeft } from '@/shared/core/either';
import { deleteUpload } from '@/shared/utils/file.utils';
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
    if (isLeft(candidatesResult)) {
      this.logger.error(`Failed to list accounts due for purge: ${candidatesResult.value.message}`);
      return;
    }

    for (const candidate of candidatesResult.value) {
      const purgeResult = await this.accountLifecycleRepository.purge(candidate.id, new Date());
      if (isLeft(purgeResult)) {
        this.logger.error(`Failed to purge account ${candidate.id}: ${purgeResult.value.message}`);
        continue;
      }

      deleteUpload(candidate.avatarUrl);
      deleteUpload(candidate.bannerUrl);
      this.logger.log(`Purged account ${candidate.id}`);
    }
  }
}
