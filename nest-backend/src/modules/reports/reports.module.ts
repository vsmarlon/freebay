import { Module } from '@nestjs/common';
import { ReportsController } from './reports.controller';
import { ReportsUseCasesModule } from './usecases/reports-usecases.module';
import { ReportsService } from './reports.service';

@Module({
  imports: [ReportsUseCasesModule],
  controllers: [ReportsController],
  providers: [ReportsService],
  exports: [ReportsService],
})
export class ReportsModule {}
