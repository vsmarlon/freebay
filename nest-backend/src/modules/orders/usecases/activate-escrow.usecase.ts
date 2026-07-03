import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { OrderRepository } from '../domain/repositories/order.repository';

@Injectable()
export class ActivateEscrowUseCase {
  constructor(private readonly orderRepository: OrderRepository) {}

  async execute(orderId: string): Promise<Either<AppError, { activated: boolean }>> {
    const orderResult = await this.orderRepository.findById(orderId);
    if (isLeft(orderResult)) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    const result = await this.orderRepository.activateEscrow(
      orderId,
      orderResult.value.sellerId,
      orderResult.value.sellerAmount,
    );
    if (isLeft(result)) return left(result.value);

    return right({ activated: true });
  }
}
