import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PaymentProvider, PaymentIntentParams } from '../domain/providers/payment-provider.interface';
import { CreatePaymentIntentInput, CreatePaymentIntentOutput } from '../dtos/payment.dto';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { UserRepository } from '../../auth/domain/repositories/user.repository';
import { TransactionRepository } from '../domain/repositories/transaction.repository';

@Injectable()
export class CreatePaymentIntentUseCase {
  private readonly logger = new Logger(CreatePaymentIntentUseCase.name);

  constructor(
    private readonly orderRepository: OrderRepository,
    private readonly userRepository: UserRepository,
    private readonly transactionRepository: TransactionRepository,
    private readonly paymentProvider: PaymentProvider,
  ) {}

  async execute(
    input: CreatePaymentIntentInput,
  ): Promise<Either<AppError, CreatePaymentIntentOutput>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (isLeft(orderResult)) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    const order = orderResult.value;
    if (order.buyerId !== input.userId) {
      return left(new BadRequestError('Order does not belong to this user'));
    }

    const userResult = await this.userRepository.findPaymentInfo(input.userId);
    if (isLeft(userResult)) return left(userResult.value);

    const user = userResult.value ?? { displayName: '', email: '', cpf: null };

    // No CPF check here — PaymentIntent is card-only (Stripe PaymentSheet).
    // CPF is only required for Checkout Session (PIX auto-offer on web).

    // Guard against replaying a Checkout Session's key on the mobile flow
    const idempotencyKey = `pi:${input.orderId}`;

    const existingResult = await this.transactionRepository.findByDerivedKey(idempotencyKey);
    if (isLeft(existingResult)) return left(existingResult.value);

    const existing = existingResult.value;

    if (existing?.status === 'PAID') {
      return left(new BadRequestError('Order already paid'));
    }

    if (
      existing?.status === 'PENDING' &&
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
      (existing.status !== 'PENDING' || !existing.externalId?.startsWith('pi_'))
    ) {
      return left(new BadRequestError('Order is not payable'));
    }

    const params: PaymentIntentParams = {
      orderId: input.orderId,
      amount: order.amount,
      currency: 'brl',
      receiptEmail: user.email ?? undefined,
      idempotencyKey,
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
      paymentMethod: 'CREDIT_CARD',
      idempotencyKey,
    });
    if (isLeft(upsertResult)) return left(upsertResult.value);

    return right({
      paymentIntentClientSecret: pi.clientSecret,
      orderId: input.orderId,
    });
  }
}
