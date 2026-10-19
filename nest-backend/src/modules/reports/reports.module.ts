import { Module } from '@nestjs/common';
import { ReportsController } from './reports.controller';
import { ReportsUseCasesModule } from './usecases/reports-usecases.module';

@Module({
  imports: [ReportsUseCasesModule],
  controllers: [ReportsController],
})
export class ReportsModule {}
