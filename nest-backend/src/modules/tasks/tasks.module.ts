import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { StoryCleanupTask } from './story-cleanup.task';
import { DisputeCleanupTask } from './dispute-cleanup.task';
import { EscrowReleaseTask } from './escrow-release.task';

@Module({
  imports: [ScheduleModule.forRoot()],
  providers: [PrismaService, StoryCleanupTask, DisputeCleanupTask, EscrowReleaseTask],
})
export class TasksModule {}
