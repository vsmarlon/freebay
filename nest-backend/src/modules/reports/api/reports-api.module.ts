import { Module } from '@nestjs/common';
import { ReportsUseCasesModule } from '../usecases/reports-usecases.module';
import { ReportsService } from './reports.service';

@Module({
  imports: [ReportsUseCasesModule],
  providers: [ReportsService],
  exports: [ReportsService],
})
export class ReportsApiModule {}
