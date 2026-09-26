import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { DisputeStatus } from '@prisma/client';
import { DisputeResolutionExecutionService } from '@/modules/disputes/services/dispute-resolution-execution.service';
import { ACTIVE_DISPUTE_STATUSES, DISPUTE_AUTO_RESOLUTION } from '@/modules/disputes/dispute.constants';

@Injectable()
export class DisputeCleanupTask {
  private readonly logger = new Logger(DisputeCleanupTask.name);

  constructor(
    private prisma: PrismaService,
    private resolutionExecution: DisputeResolutionExecutionService,
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
      await this.prisma.$transaction(async (tx) => {
        const currentDispute = await tx.dispute.findUnique({
          where: { id: dispute.id },
        });

        if (!currentDispute || !ACTIVE_DISPUTE_STATUSES.includes(currentDispute.status)) {
          return;
        }

        await tx.dispute.update({
          where: { id: dispute.id },
          data: {
            status: DisputeStatus.RESOLVED,
            resolution: DISPUTE_AUTO_RESOLUTION,
            resolvedAt: currentTime,
          },
        });

        await this.resolutionExecution.resolveInFavorOfSeller(tx, dispute);
      });

      this.logger.log(`Auto-resolved expired dispute ${dispute.id} in favor of seller`);
    }
  }
}
