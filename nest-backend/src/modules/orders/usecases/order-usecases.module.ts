import { Module } from '@nestjs/common';
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
    CreateOrderUseCase,
    ConfirmDeliveryUseCase,
    MarkAsShippedUseCase,
    MarkAsDeliveredUseCase,
    CancelOrderUseCase,
  ],
  exports: [
    PrismaOrderRepository,
    CreateOrderUseCase,
    ConfirmDeliveryUseCase,
    MarkAsShippedUseCase,
    MarkAsDeliveredUseCase,
    CancelOrderUseCase,
  ],
})
export class OrderUseCasesModule {}
