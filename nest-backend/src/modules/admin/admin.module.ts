import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { ModerationDatabaseRepository } from './data/repositories/moderation-database.repository';
import { ListReportsUseCase } from './usecases/list-reports.usecase';
import { ResolveReportUseCase } from './usecases/resolve-report.usecase';
import { SuspendUserUseCase } from './usecases/suspend-user.usecase';
import { RemoveContentUseCase } from './usecases/remove-content.usecase';
import { ListModerationActionsUseCase } from './usecases/list-moderation-actions.usecase';
import { PaymentsModule } from '../payments/payments.module';
import { ListTransferFailuresUseCase } from './usecases/list-transfer-failures.usecase';

@Module({
  controllers: [AdminController],
  imports: [PaymentsModule],
  providers: [
    ModerationDatabaseRepository,
    ListReportsUseCase,
    ResolveReportUseCase,
    SuspendUserUseCase,
    RemoveContentUseCase,
    ListModerationActionsUseCase,
    ListTransferFailuresUseCase,
  ],
})
export class AdminModule {}
