import { Module } from '@nestjs/common';
import { ReportDatabaseRepository } from '../data/repositories/report-database.repository';
import { CreateReportUseCase } from './create-report.usecase';

@Module({
  providers: [
    ReportDatabaseRepository,
    CreateReportUseCase,
  ],
  exports: [
    CreateReportUseCase,
  ],
})
export class ReportsUseCasesModule {}
