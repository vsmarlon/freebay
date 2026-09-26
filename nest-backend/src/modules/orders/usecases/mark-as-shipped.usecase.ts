import { Injectable } from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, InvalidOrderStateError } from '@/shared/core/errors';
import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { MarkAsShippedInput } from '../dtos/order.dto';

@Injectable()
export class MarkAsShippedUseCase {
  constructor(private readonly orderRepository: PrismaOrderRepository) {}

  async execute(input: MarkAsShippedInput): Promise<Either<AppError, void>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (orderResult.isLeft()) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    if (orderResult.value.sellerId !== input.sellerId) {
      return left(new UnauthorizedError('Only seller can mark as shipped'));
    }

    if (orderResult.value.status !== OrderStatus.CONFIRMED) {
      return left(new InvalidOrderStateError('CONFIRMED to ship', orderResult.value.status));
    }

    const result = await this.orderRepository.markShipped(input.orderId);
    if (result.isLeft()) return left(result.value);
    if (!result.value) return left(new InvalidOrderStateError('CONFIRMED sem reembolso pendente'));

    return right(undefined);
  }
}
