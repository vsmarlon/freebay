import { Module } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ReportRepository } from '../domain/repositories/report.repository';
import { ReportDatabaseRepository } from '../data/repositories/report-database.repository';
import { CreateReportUseCase } from './create-report.usecase';
import { GetReportsUseCase } from './get-reports.usecase';
import { ResolveReportUseCase } from './resolve-report.usecase';

@Module({
  providers: [
    { provide: PrismaClient, useExisting: PrismaService },
    { provide: ReportRepository, useClass: ReportDatabaseRepository },
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
