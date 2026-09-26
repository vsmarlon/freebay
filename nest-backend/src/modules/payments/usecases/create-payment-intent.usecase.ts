import { Inject, Injectable, Logger } from '@nestjs/common';
import { OrderStatus, PaymentMethod, TransactionStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import {
  AppError,
  NotFoundError,
  BadRequestError,
  InvalidOrderStateError,
} from '@/shared/core/errors';
import { PaymentIntentParams } from '../types/payment-provider.types';
import { StripeProvider } from '../providers/stripe-provider';
import { CreatePaymentIntentInput, CreatePaymentIntentOutput } from '../dtos/payment.dto';
import { PrismaOrderRepository } from '../../orders/data/repositories/order-database.repository';
import { UserDatabaseRepository } from '../../auth/data/repositories/user-database.repository';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';

@Injectable()
export class CreatePaymentIntentUseCase {
  private readonly logger = new Logger(CreatePaymentIntentUseCase.name);

  constructor(
    private readonly orderRepository: PrismaOrderRepository,
    private readonly userRepository: UserDatabaseRepository,
    private readonly transactionRepository: TransactionDatabaseRepository,
    @Inject(StripeProvider) private readonly paymentProvider: StripeProvider,
  ) {}

  async execute(
    input: CreatePaymentIntentInput,
  ): Promise<Either<AppError, CreatePaymentIntentOutput>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (orderResult.isLeft()) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    const order = orderResult.value;
    if (order.buyerId !== input.userId) {
      return left(new BadRequestError('Order does not belong to this user'));
    }

    if (order.status !== OrderStatus.PENDING) {
      return left(new InvalidOrderStateError(OrderStatus.PENDING, order.status));
    }

    const userResult = await this.userRepository.findPaymentInfo(input.userId);
    if (userResult.isLeft()) return left(userResult.value);

    const user = userResult.value ?? { displayName: '', email: '', cpf: null };

    const idempotencyKey = `pi:${input.orderId}`;

    const existingResult = await this.transactionRepository.findByOrderId(input.orderId);
    if (existingResult.isLeft()) return left(existingResult.value);

    const existing = existingResult.value;

    if (existing?.status === TransactionStatus.PAID) {
      return left(new BadRequestError('Order already paid'));
    }

    if (
      existing?.status === TransactionStatus.PENDING &&
      existing.externalId?.startsWith('cs_')
    ) {
      return left(
        new BadRequestError(
          'A Checkout Session is already active for this order. Complete it in the browser or wait for it to expire.',
        ),
      );
    }

    if (
      existing &&
      (existing.status !== TransactionStatus.PENDING || !existing.externalId?.startsWith('pi_'))
    ) {
      return left(new BadRequestError('Order is not payable'));
    }

    const params: PaymentIntentParams = {
      orderId: input.orderId,
      amount: order.amount,
      currency: 'brl',
      receiptEmail: user.email ?? undefined,
      idempotencyKey,
      transferGroup: `freebay:order:${input.orderId}`,
    };

    const paymentIntentResult = await this.paymentProvider.createPaymentIntent(params);
    if (paymentIntentResult.isLeft()) {
      this.logger.error(`PaymentIntent creation failed: ${paymentIntentResult.value.message}`);
      return left(paymentIntentResult.value);
    }

    const pi = paymentIntentResult.value;

    const upsertResult = await this.transactionRepository.upsertTransaction({
      orderId: input.orderId,
      externalId: pi.paymentIntentId,
      amount: order.amount,
      platformFee: order.platformFee,
      sellerAmount: order.sellerAmount,
      paymentMethod: PaymentMethod.CREDIT_CARD,
      idempotencyKey,
    });
    if (upsertResult.isLeft()) return left(upsertResult.value);

    return right({
      paymentIntentClientSecret: pi.clientSecret,
      orderId: input.orderId,
    });
  }
}
