import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { TransactionRepository } from '../domain/repositories/transaction.repository';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { SellerPayoutService } from '../services/seller-payout.service';

@Injectable()
export class ProcessRefundUseCase {
  private readonly logger = new Logger(ProcessRefundUseCase.name);

  constructor(
    private readonly transactionRepo: TransactionRepository,
    private readonly orderRepo: OrderRepository,
    private readonly payoutService: SellerPayoutService,
  ) {}

  async execute(chargeId: string): Promise<Either<DatabaseError, void>> {
    const found = await this.transactionRepo.findByChargeId(chargeId);
    if (isLeft(found)) return left(found.value);
    if (!found.value) return right(undefined);

    const transaction = found.value;
    const order = transaction.order;

    if (order.status === 'CANCELLED') {
      return right(undefined);
    }

    await this.payoutService.reverseForOrder(order.id);

    const cancelled = await this.orderRepo.cancelOrder({
      orderId: order.id,
      productId: order.productId,
      buyerId: order.buyerId,
      amount: order.amount,
      status: order.status,
      orderQuantity: order.quantity,
      sellerId: order.sellerId,
      sellerAmount: order.sellerAmount,
    });
    if (isLeft(cancelled)) return left(new DatabaseError('Failed to cancel refunded order'));

    this.logger.log(`Refund processed for order ${order.id} (charge ${chargeId})`);
    return right(undefined);
  }
}
