import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, InvalidOrderStateError } from '@/shared/core/errors';
import { OrderRepository } from '../domain/repositories/order.repository';
import { MarkAsShippedInput } from '../dtos/order.dto';

@Injectable()
export class MarkAsShippedUseCase {
  constructor(private readonly orderRepository: OrderRepository) {}

  async execute(input: MarkAsShippedInput): Promise<Either<AppError, { shipped: boolean }>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (isLeft(orderResult)) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    if (orderResult.value.sellerId !== input.sellerId) {
      return left(new UnauthorizedError('Only seller can mark as shipped'));
    }

    if (orderResult.value.status !== 'CONFIRMED') {
      return left(new InvalidOrderStateError('CONFIRMED to ship', orderResult.value.status));
    }

    const result = await this.orderRepository.update(input.orderId, { status: 'SHIPPED' });
    if (isLeft(result)) return left(result.value);

    return right({ shipped: true });
  }
}
