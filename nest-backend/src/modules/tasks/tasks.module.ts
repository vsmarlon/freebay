import { Module } from '@nestjs/common';
import { PaymentsModule } from '../payments/payments.module';
import { UsersModule } from '../users/users.module';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { StoryCleanupTask } from './story-cleanup.task';
import { DisputeCleanupTask } from './dispute-cleanup.task';
import { EscrowReleaseTask } from './escrow-release.task';
import { AccountDeletionTask } from './account-deletion.task';
import { CheckoutExpiryTask } from './checkout-expiry.task';
import { DisputeResolutionExecutionService } from '../disputes/services/dispute-resolution-execution.service';
import { MagicLinkDatabaseRepository } from '../auth/data/repositories/magic-link-database.repository';
import { MagicLinkCleanupTask } from './magic-link-cleanup.task';
import { TransferReconciliationTask } from './transfer-reconciliation.task';

@Module({
  imports: [ScheduleModule.forRoot(), PaymentsModule, UsersModule],
  providers: [
    PrismaService,
    StoryCleanupTask,
    DisputeCleanupTask,
    EscrowReleaseTask,
    AccountDeletionTask,
    CheckoutExpiryTask,
    DisputeResolutionExecutionService,
    MagicLinkDatabaseRepository,
    MagicLinkCleanupTask,
    TransferReconciliationTask,
  ],
})
export class TasksModule {}
