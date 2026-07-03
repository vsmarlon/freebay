import { Module } from '@nestjs/common';
import { BugReportController } from './bug-report.controller';
import { BugReportUseCasesModule } from './usecases/bug-report-usecases.module';

@Module({
  imports: [BugReportUseCasesModule],
  controllers: [BugReportController],
})
export class BugReportModule {}
