import { Module } from '@nestjs/common';
import { OrderRepository } from '../domain/repositories/order.repository';
import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { CreateOrderUseCase } from './create-order.usecase';
import { ConfirmDeliveryUseCase } from './confirm-delivery.usecase';
import { MarkAsShippedUseCase } from './mark-as-shipped.usecase';
import { MarkAsDeliveredUseCase } from './mark-as-delivered.usecase';
import { CancelOrderUseCase } from './cancel-order.usecase';
import { NotificationsModule } from '@/modules/notifications/notifications.module';
import { PaymentsModule } from '@/modules/payments/payments.module';

@Module({
  imports: [NotificationsModule, PaymentsModule],
  providers: [
    PrismaOrderRepository,
    { provide: OrderRepository, useExisting: PrismaOrderRepository },
    CreateOrderUseCase,
    ConfirmDeliveryUseCase,
    MarkAsShippedUseCase,
    MarkAsDeliveredUseCase,
    CancelOrderUseCase,
  ],
  exports: [
    OrderRepository,
    PrismaOrderRepository,
    CreateOrderUseCase,
    ConfirmDeliveryUseCase,
    MarkAsShippedUseCase,
    MarkAsDeliveredUseCase,
    CancelOrderUseCase,
  ],
})
export class OrderUseCasesModule {}
