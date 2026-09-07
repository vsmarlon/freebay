import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { ModerationRepository } from './domain/repositories/moderation.repository';
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
    { provide: ModerationRepository, useExisting: ModerationDatabaseRepository },
    ListReportsUseCase,
    ResolveReportUseCase,
    SuspendUserUseCase,
    RemoveContentUseCase,
    ListModerationActionsUseCase,
  ],
})
export class AdminModule {}
