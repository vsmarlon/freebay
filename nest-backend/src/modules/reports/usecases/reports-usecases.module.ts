import { Module } from '@nestjs/common';
import { ReportDatabaseRepository } from '../data/repositories/report-database.repository';
import { CreateReportUseCase } from './create-report.usecase';
import { GetReportsUseCase } from './get-reports.usecase';
import { ResolveReportUseCase } from './resolve-report.usecase';

@Module({
  providers: [
    ReportDatabaseRepository,
    CreateReportUseCase,
    GetReportsUseCase,
    ResolveReportUseCase,
  ],
  exports: [
    CreateReportUseCase,
    GetReportsUseCase,
    ResolveReportUseCase,
  ],
})
export class ReportsUseCasesModule {}
