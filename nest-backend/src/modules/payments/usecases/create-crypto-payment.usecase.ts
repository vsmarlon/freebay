import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { CryptoPaymentProvider } from '../domain/providers/crypto-payment.provider.interface';
import { CryptoCurrency } from '../types/crypto-payment.types';
import { CreateCryptoPaymentInput, CreateCryptoPaymentOutput } from '../dtos/payment.dto';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';

@Injectable()
export class CreateCryptoPaymentUseCase {
  private readonly logger = new Logger(CreateCryptoPaymentUseCase.name);

  constructor(
    private readonly orderRepository: OrderRepository,
    private readonly cryptoPaymentProvider: CryptoPaymentProvider,
  ) {}

  async execute(
    input: CreateCryptoPaymentInput,
  ): Promise<Either<AppError, CreateCryptoPaymentOutput>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (isLeft(orderResult)) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    const order = orderResult.value;
    if (order.buyerId !== input.userId) {
      return left(new BadRequestError('Order does not belong to this user'));
    }

    if (order.status !== 'PENDING') {
      return left(new BadRequestError('Order is not in pending status'));
    }

    const currency = (input.currency as CryptoCurrency) || CryptoCurrency.XMR;

    const addressResult = await this.cryptoPaymentProvider.generateEphemeralAddress(
      order.id,
      currency,
      order.amount,
    );

    if (addressResult.isLeft()) {
      this.logger.error(`Crypto address generation failed: ${addressResult.value.message}`);
      return left(addressResult.value);
    }

    const payload = addressResult.value;

    return right({
      orderId: payload.orderId,
      currency: payload.currency,
      address: payload.address,
      paymentId: payload.paymentId,
      uriQrCode: payload.uriQrCode,
      amountAtomic: payload.amountAtomic,
      amountHuman: payload.amountHuman,
      expiresAt: payload.expiresAt,
    });
  }
}
