import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { AuthUser } from '@/shared/core/types';
import { UserRole } from '@prisma/client';
import { OrderFullPayload } from '../types/order.types';

@Injectable()
export class GetOrderUseCase {
  constructor(private readonly orderRepository: PrismaOrderRepository) {}

  async execute(
    id: string,
    user: AuthUser,
  ): Promise<Either<AppError, { order: OrderFullPayload }>> {
    const result = await this.orderRepository.findById(id);
    if (result.isLeft()) return left(result.value);
    if (!result.value) return left(new NotFoundError('Pedido'));

    const order = result.value;
    if (
      order.buyerId !== user.userId &&
      order.sellerId !== user.userId &&
      user.role !== UserRole.ADMIN
    ) {
      return left(
        new ForbiddenError(
          'Você não tem permissão para visualizar este pedido',
        ),
      );
    }

    return right({ order });
  }
}
