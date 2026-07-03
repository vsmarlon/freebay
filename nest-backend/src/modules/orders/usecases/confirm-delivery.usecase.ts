import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, InvalidOrderStateError } from '@/shared/core/errors';
import { OrderRepository } from '../domain/repositories/order.repository';
import { ConfirmDeliveryInput } from '../dtos/order.dto';

@Injectable()
export class ConfirmDeliveryUseCase {
  constructor(private readonly orderRepository: OrderRepository) {}

  async execute(input: ConfirmDeliveryInput): Promise<Either<AppError, { confirmed: boolean; sellerAmount: number }>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (isLeft(orderResult)) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    const order = orderResult.value;
    if (order.buyerId !== input.buyerId) {
      return left(new UnauthorizedError('Only buyer can confirm delivery'));
    }

    if (order.status !== 'CONFIRMED' && order.status !== 'DELIVERED') {
      return left(new InvalidOrderStateError('CONFIRMED or DELIVERED', order.status));
    }

    const result = await this.orderRepository.confirmDelivery({
      orderId: input.orderId,
      sellerId: order.sellerId,
      sellerAmount: order.sellerAmount,
    });
    if (isLeft(result)) return left(result.value);

    return right({ confirmed: true, sellerAmount: order.sellerAmount });
  }
}
