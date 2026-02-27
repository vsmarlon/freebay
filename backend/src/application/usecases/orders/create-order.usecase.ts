import { IOrderRepository, IWalletRepository } from '@/domain/repositories';
import { OrderEntity } from '@/domain/entities';
import { Either, left, right } from '@/domain/either';
import { AppError, NotFoundError, ForbiddenError, InvalidOrderStateError } from '@/domain/errors';
import { CreateOrderInput } from './input/CreateOrderInput';

export class CreateOrderUseCase {
  constructor(
    private orderRepository: IOrderRepository,
    private walletRepository: IWalletRepository,
  ) {}

  async execute(input: CreateOrderInput): Promise<Either<AppError, OrderEntity>> {
    const platformFee = Math.round(input.amount * (input.platformFeePercent / 100));
    const sellerAmount = input.amount - platformFee;

    const order = await this.orderRepository.create({
      buyerId: input.buyerId,
      sellerId: input.sellerId,
      productId: input.productId,
      amount: input.amount,
      platformFee,
      sellerAmount,
      status: 'PENDING',
      escrowStatus: 'HELD',
      meetingScheduledAt: null,
      deliveryConfirmedAt: null,
    });

    return right(order);
  }
}

export class ConfirmDeliveryUseCase {
  constructor(
    private orderRepository: IOrderRepository,
    private walletRepository: IWalletRepository,
  ) {}

  async execute(orderId: string, buyerId: string): Promise<Either<AppError, OrderEntity>> {
    const order = await this.orderRepository.findById(orderId);
    if (!order) {
      return left(new NotFoundError('Pedido'));
    }
    if (order.buyerId !== buyerId) {
      return left(new ForbiddenError('Apenas o comprador pode confirmar a entrega'));
    }
    if (order.status !== 'CONFIRMED') {
      return left(new InvalidOrderStateError('CONFIRMED', order.status));
    }

    const updatedOrder = await this.orderRepository.update(orderId, {
      status: 'COMPLETED',
      escrowStatus: 'RELEASED',
      deliveryConfirmedAt: new Date(),
    });

    // Release escrow: move from pending to available
    const wallet = await this.walletRepository.findByUserId(order.sellerId);
    if (wallet) {
      await this.walletRepository.updateBalance(order.sellerId, {
        pendingBalance: wallet.pendingBalance - order.sellerAmount,
        availableBalance: wallet.availableBalance + order.sellerAmount,
        totalEarned: wallet.totalEarned + order.sellerAmount,
      });
    }

    return right(updatedOrder);
  }
}
