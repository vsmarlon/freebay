import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { DisputeResolutionExecutionService } from '@/modules/disputes/services/dispute-resolution-execution.service';

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
        status: { in: ['OPEN', 'AWAITING_SELLER', 'AWAITING_BUYER'] },
        expiresAt: { lt: currentTime },
      },
      include: { order: true },
    });

    for (const dispute of expiredDisputes) {
      await this.prisma.$transaction(async (tx) => {
        const currentDispute = await tx.dispute.findUnique({
          where: { id: dispute.id },
        });

        if (!currentDispute || !['OPEN', 'AWAITING_SELLER', 'AWAITING_BUYER'].includes(currentDispute.status)) {
          return;
        }

        await tx.dispute.update({
          where: { id: dispute.id },
          data: {
            status: 'RESOLVED',
            resolution: 'Auto-resolved: dispute window expired',
            resolvedAt: currentTime,
          },
        });

        await this.resolutionExecution.resolveInFavorOfSeller(tx, dispute);
      });

      this.logger.log(`Auto-resolved expired dispute ${dispute.id} in favor of seller`);
    }
  }
}
