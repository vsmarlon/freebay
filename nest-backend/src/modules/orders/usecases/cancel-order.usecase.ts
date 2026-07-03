import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, InvalidOrderStateError } from '@/shared/core/errors';
import { OrderRepository } from '../domain/repositories/order.repository';
import { CancelOrderInput } from '../dtos/order.dto';

@Injectable()
export class CancelOrderUseCase {
  constructor(private readonly orderRepository: OrderRepository) {}

  async execute(input: CancelOrderInput): Promise<Either<AppError, { cancelled: boolean }>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (isLeft(orderResult)) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    const order = orderResult.value;
    if (order.buyerId !== input.userId && order.sellerId !== input.userId) {
      return left(new UnauthorizedError('Not authorized to cancel this order'));
    }
    if (order.status !== 'PENDING' && order.status !== 'CONFIRMED') {
      return left(new InvalidOrderStateError('PENDING or CONFIRMED', order.status));
    }

    const productQuantity = order.product?.quantity ?? 1;

    const result = await this.orderRepository.cancelOrder({
      orderId: input.orderId,
      productId: order.productId,
      buyerId: order.buyerId,
      amount: order.amount,
      status: order.status,
      quantity: productQuantity,
    });
    if (isLeft(result)) return left(result.value);

    return right({ cancelled: true });
  }
}
