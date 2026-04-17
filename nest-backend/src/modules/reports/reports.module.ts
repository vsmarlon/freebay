import { Module } from '@nestjs/common';
import { ReportsController } from './reports.controller';
import { CreateReportUseCase, GetReportsUseCase, ResolveReportUseCase } from './usecases/report.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [ReportsController],
  providers: [
    CreateReportUseCase,
    GetReportsUseCase,
    ResolveReportUseCase,
    PrismaService,
  ],
})
export class ReportsModule {}
