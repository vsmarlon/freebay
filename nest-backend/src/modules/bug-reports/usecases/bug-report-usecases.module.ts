import { Module } from '@nestjs/common';
import { BugReportRepository } from '../domain/repositories/bug-report.repository';
import { BugReportDatabaseRepository } from '../data/repositories/bug-report-database.repository';
import { CreateBugReportUseCase } from './create-bug-report.usecase';

@Module({
  providers: [
    { provide: BugReportRepository, useClass: BugReportDatabaseRepository },
    CreateBugReportUseCase,
  ],
  exports: [CreateBugReportUseCase],
})
export class BugReportUseCasesModule {}
