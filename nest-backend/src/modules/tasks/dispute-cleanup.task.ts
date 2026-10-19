import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ACTIVE_DISPUTE_STATUSES } from '@/modules/disputes/dispute.constants';

@Injectable()
export class DisputeCleanupTask {
  private readonly logger = new Logger(DisputeCleanupTask.name);

  constructor(
    private prisma: PrismaService,
  ) {}

  @Cron(CronExpression.EVERY_30_MINUTES)
  async cleanupExpiredDisputes(now?: Date) {
    const currentTime = now ?? new Date();
    const expiredDisputes = await this.prisma.dispute.findMany({
      where: {
        status: { in: ACTIVE_DISPUTE_STATUSES },
        expiresAt: { lt: currentTime },
      },
      include: { order: true },
    });

    for (const dispute of expiredDisputes) {
      this.logger.warn(`Expired dispute ${dispute.id} remains held for manual review`);
    }
  }
}
