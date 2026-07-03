import { Module } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { OrderRepository } from '../domain/repositories/order.repository';
import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { CreateOrderUseCase } from './create-order.usecase';
import { ConfirmDeliveryUseCase } from './confirm-delivery.usecase';
import { ActivateEscrowUseCase } from './activate-escrow.usecase';
import { MarkAsShippedUseCase } from './mark-as-shipped.usecase';
import { MarkAsDeliveredUseCase } from './mark-as-delivered.usecase';
import { CancelOrderUseCase } from './cancel-order.usecase';
import { NotificationsModule } from '@/modules/notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  providers: [
    { provide: PrismaClient, useExisting: PrismaService },
    PrismaOrderRepository,
    { provide: OrderRepository, useExisting: PrismaOrderRepository },
    CreateOrderUseCase,
    ConfirmDeliveryUseCase,
    ActivateEscrowUseCase,
    MarkAsShippedUseCase,
    MarkAsDeliveredUseCase,
    CancelOrderUseCase,
  ],
  exports: [
    PrismaOrderRepository,
    CreateOrderUseCase,
    ConfirmDeliveryUseCase,
    ActivateEscrowUseCase,
    MarkAsShippedUseCase,
    MarkAsDeliveredUseCase,
    CancelOrderUseCase,
  ],
})
export class OrderUseCasesModule {}
