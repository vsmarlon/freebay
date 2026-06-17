import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class StoryCleanupTask {
  private readonly logger = new Logger(StoryCleanupTask.name);

  constructor(private prisma: PrismaService) {}

  @Cron(CronExpression.EVERY_HOUR)
  async cleanupExpiredStories() {
    const result = await this.prisma.story.deleteMany({
      where: { expiresAt: { lt: new Date() } },
    });

    if (result.count > 0) {
      this.logger.log(`Cleaned up ${result.count} expired stories`);
    }
  }
}
