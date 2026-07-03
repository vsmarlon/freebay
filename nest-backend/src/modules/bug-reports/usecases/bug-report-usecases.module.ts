import { Module } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BugReportRepository } from '../domain/repositories/bug-report.repository';
import { BugReportDatabaseRepository } from '../data/repositories/bug-report-database.repository';
import { CreateBugReportUseCase } from './create-bug-report.usecase';

@Module({
  providers: [
    { provide: PrismaClient, useExisting: PrismaService },
    { provide: BugReportRepository, useClass: BugReportDatabaseRepository },
    CreateBugReportUseCase,
  ],
  exports: [CreateBugReportUseCase],
})
export class BugReportUseCasesModule {}
