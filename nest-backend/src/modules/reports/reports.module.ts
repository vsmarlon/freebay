import { Module } from '@nestjs/common';
import { ReportsController } from './reports.controller';
import { ReportsUseCasesModule } from './usecases/reports-usecases.module';
import { ReportsApiModule } from './api/reports-api.module';

@Module({
  imports: [ReportsUseCasesModule, ReportsApiModule],
  controllers: [ReportsController],
})
export class ReportsModule {}
