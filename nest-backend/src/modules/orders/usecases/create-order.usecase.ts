import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { CreateOrderInput, CreateOrderOutput } from '../dtos/order.dto';

@Injectable()
export class CreateOrderUseCase {
  constructor(
    private readonly orderRepository: PrismaOrderRepository,
    private readonly notificationService: NotificationService,
  ) {}

  async execute(input: CreateOrderInput): Promise<Either<AppError, CreateOrderOutput>> {
    const result = await this.orderRepository.createOrderWithReservation({
      buyerId: input.buyerId,
      productId: input.productId,
      platformFeePercent: input.platformFeePercent,
    });

    if (result.isLeft()) return left(result.value);

    this.notificationService.create({
      userId: input.buyerId,
      type: 'ORDER',
      title: 'Pedido criado',
      body: 'Pedido criado! Aproveite para combinar os detalhes da entrega.',
      extraData: { type: 'order', orderId: result.value.id },
    });
    this.notificationService.create({
      userId: result.value.sellerId,
      type: 'ORDER',
      title: 'Novo pedido',
      body: `Você recebeu um pedido`,
      extraData: { type: 'order', orderId: result.value.id },
    });

    return right(result.value);
  }
}
