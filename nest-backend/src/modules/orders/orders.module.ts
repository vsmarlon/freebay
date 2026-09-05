import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrderUseCasesModule } from './usecases/order-usecases.module';

@Module({
  imports: [OrderUseCasesModule],
  controllers: [OrdersController],
  exports: [OrderUseCasesModule],
})
export class OrdersModule {}
