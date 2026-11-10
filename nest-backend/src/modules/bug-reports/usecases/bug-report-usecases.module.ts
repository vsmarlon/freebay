import { Module } from '@nestjs/common';
import { BugReportDatabaseRepository } from '../data/repositories/bug-report-database.repository';
import { CreateBugReportUseCase } from './create-bug-report.usecase';

@Module({
  providers: [
    BugReportDatabaseRepository,
    CreateBugReportUseCase,
  ],
  exports: [CreateBugReportUseCase],
})
export class BugReportUseCasesModule {}
