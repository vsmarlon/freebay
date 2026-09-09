import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { MagicLinkDatabaseRepository } from '../auth/data/repositories/magic-link-database.repository';

export const MAGIC_LINK_EXPIRED_RETENTION_DAYS = 1;
export const MAGIC_LINK_CONSUMED_RETENTION_DAYS = 30;

@Injectable()
export class MagicLinkCleanupTask {
  private readonly logger = new Logger(MagicLinkCleanupTask.name);

  constructor(private readonly repository: MagicLinkDatabaseRepository) {}

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async cleanupMagicLinks(now = new Date()): Promise<void> {
    const expiredBefore = new Date(now.getTime() - MAGIC_LINK_EXPIRED_RETENTION_DAYS * 86400000);
    const consumedBefore = new Date(now.getTime() - MAGIC_LINK_CONSUMED_RETENTION_DAYS * 86400000);
    const result = await this.repository.deleteExpiredOrConsumed(expiredBefore, consumedBefore);
    if (result.isRight() && result.value > 0) this.logger.log(`Cleaned up ${result.value} magic links`);
  }
}
