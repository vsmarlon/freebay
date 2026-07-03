import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, InvalidOrderStateError } from '@/shared/core/errors';
import { OrderRepository } from '../domain/repositories/order.repository';
import { MarkAsDeliveredInput } from '../dtos/order.dto';

@Injectable()
export class MarkAsDeliveredUseCase {
  constructor(private readonly orderRepository: OrderRepository) {}

  async execute(input: MarkAsDeliveredInput): Promise<Either<AppError, { delivered: boolean }>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (isLeft(orderResult)) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    if (orderResult.value.buyerId !== input.buyerId) {
      return left(new UnauthorizedError('Only buyer can mark as delivered'));
    }

    if (orderResult.value.status !== 'SHIPPED') {
      return left(new InvalidOrderStateError('SHIPPED to deliver', orderResult.value.status));
    }

    const result = await this.orderRepository.update(input.orderId, {
      status: 'DELIVERED',
      deliveryConfirmedAt: new Date(),
    });
    if (isLeft(result)) return left(result.value);

    return right({ delivered: true });
  }
}
