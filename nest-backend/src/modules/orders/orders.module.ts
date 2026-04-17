import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { CreateOrderUseCase, ConfirmDeliveryUseCase, ActivateEscrowUseCase } from './usecases/order.usecase';
import { PrismaOrderRepository } from './repositories/order.repository';
import { PrismaProductRepository } from '../products/repositories/product.repository';
import { PrismaWalletRepository } from '../wallet/repositories/wallet.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [OrdersController],
  providers: [
    CreateOrderUseCase,
    ConfirmDeliveryUseCase,
    ActivateEscrowUseCase,
    PrismaOrderRepository,
    PrismaProductRepository,
    PrismaWalletRepository,
    PrismaService,
  ],
})
export class OrdersModule {}
