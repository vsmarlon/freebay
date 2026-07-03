import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderUseCasesModule } from './usecases/order-usecases.module';
import { PrismaOrderRepository } from './data/repositories/order-database.repository';

@Module({
  imports: [OrderUseCasesModule],
  controllers: [OrdersController],
  providers: [OrdersService, PrismaOrderRepository],
  exports: [PrismaOrderRepository, OrdersService],
})
export class OrdersModule {}
