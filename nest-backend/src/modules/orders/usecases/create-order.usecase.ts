import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
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
    if (input.sellerId === input.buyerId) {
      return left(new BadRequestError('Cannot buy your own product'));
    }

    const platformFee = Math.round(input.amount * (input.platformFeePercent / 100));
    const sellerAmount = input.amount - platformFee;

    const result = await this.orderRepository.createOrderWithReservation({
      buyerId: input.buyerId,
      sellerId: input.sellerId,
      productId: input.productId,
      amount: input.amount,
      platformFee,
      sellerAmount,
    });

    if (isLeft(result)) return left(result.value);

    this.notificationService.create({
      userId: input.buyerId,
      type: 'ORDER',
      title: 'Pedido criado',
      body: 'Pedido criado! Aproveite para combinar os detalhes da entrega.',
      extraData: { type: 'order', orderId: result.value.id },
    });
    this.notificationService.create({
      userId: input.sellerId,
      type: 'ORDER',
      title: 'Novo pedido',
      body: `Você recebeu um pedido`,
      extraData: { type: 'order', orderId: result.value.id },
    });

    return right({
      id: result.value.id,
      buyerId: input.buyerId,
      sellerId: input.sellerId,
      productId: input.productId,
      amount: input.amount,
      status: 'PENDING',
      createdAt: new Date(),
    });
  }
}
