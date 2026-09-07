import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { ModerationDatabaseRepository } from './data/repositories/moderation-database.repository';
import { ListReportsUseCase } from './usecases/list-reports.usecase';
import { ResolveReportUseCase } from './usecases/resolve-report.usecase';
import { SuspendUserUseCase } from './usecases/suspend-user.usecase';
import { RemoveContentUseCase } from './usecases/remove-content.usecase';
import { ListModerationActionsUseCase } from './usecases/list-moderation-actions.usecase';

@Module({
  controllers: [AdminController],
  providers: [
    ModerationDatabaseRepository,
    ListReportsUseCase,
    ResolveReportUseCase,
    SuspendUserUseCase,
    RemoveContentUseCase,
    ListModerationActionsUseCase,
  ],
})
export class AdminModule {}
