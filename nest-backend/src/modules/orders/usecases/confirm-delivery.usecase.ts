import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError, InvalidOrderStateError } from '@/shared/core/errors';
import { PrismaOrderRepository } from '../data/repositories/order-database.repository';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';
import { ConfirmDeliveryInput } from '../dtos/order.dto';

@Injectable()
export class ConfirmDeliveryUseCase {
  constructor(
    private readonly orderRepository: PrismaOrderRepository,
    private readonly payoutService: SellerPayoutService,
  ) {}

  async execute(input: ConfirmDeliveryInput): Promise<Either<AppError, { sellerAmount: number }>> {
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

    await this.payoutService.payoutForOrder(input.orderId);

    return right({ sellerAmount: order.sellerAmount });
  }
}
