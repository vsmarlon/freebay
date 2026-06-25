import { Module } from '@nestjs/common';
import { ReportsController } from './reports.controller';
import { CreateReportUseCase } from './usecases/create-report.usecase';
import { GetReportsUseCase } from './usecases/get-reports.usecase';
import { ResolveReportUseCase } from './usecases/resolve-report.usecase';
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
