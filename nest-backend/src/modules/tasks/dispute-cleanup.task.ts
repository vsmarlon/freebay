import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { DISPUTE_STATUS, ESCALATABLE_DISPUTE_STATUSES } from '@/modules/disputes/domain/dispute-state';

@Injectable()
export class DisputeCleanupTask {
  private readonly logger = new Logger(DisputeCleanupTask.name);

  constructor(
    private prisma: PrismaService,
  ) {}

  @Cron(CronExpression.EVERY_30_MINUTES)
  async cleanupExpiredDisputes(now?: Date) {
    const currentTime = now ?? new Date();
    const escalated = await this.prisma.dispute.updateMany({
      where: {
        status: { in: [...ESCALATABLE_DISPUTE_STATUSES] },
        expiresAt: { lt: currentTime },
      },
      data: { status: DISPUTE_STATUS.ESCALATED },
    });

    if (escalated.count > 0) {
      this.logger.warn(`Escalated ${escalated.count} expired disputes to the admin queue`);
    }
  }
}
