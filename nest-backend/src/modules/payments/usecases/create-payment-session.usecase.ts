import { Inject, Injectable, Logger } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import {
  AppError,
  NotFoundError,
  BadRequestError,
  InvalidOrderStateError,
} from '@/shared/core/errors';
import { PaymentSessionParams } from '../types/payment-provider.types';
import { StripeProvider } from '../providers/stripe-provider';
import { CreatePaymentSessionInput, CreatePaymentSessionOutput } from '../dtos/payment.dto';
import { PrismaOrderRepository } from '../../orders/data/repositories/order-database.repository';
import { UserDatabaseRepository } from '../../auth/data/repositories/user-database.repository';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';

@Injectable()
export class CreatePaymentSessionUseCase {
  private readonly logger = new Logger(CreatePaymentSessionUseCase.name);

  constructor(
    private readonly orderRepository: PrismaOrderRepository,
    private readonly userRepository: UserDatabaseRepository,
    private readonly transactionRepository: TransactionDatabaseRepository,
    @Inject(StripeProvider) private readonly paymentProvider: StripeProvider,
  ) {}

  async execute(
    input: CreatePaymentSessionInput,
  ): Promise<Either<AppError, CreatePaymentSessionOutput>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (orderResult.isLeft()) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    const order = orderResult.value;
    if (order.buyerId !== input.userId) {
      return left(new BadRequestError('Order does not belong to this user'));
    }

    if (order.status !== 'PENDING') {
      return left(new InvalidOrderStateError('PENDING', order.status));
    }

    const userResult = await this.userRepository.findPaymentInfo(input.userId);
    if (userResult.isLeft()) return left(userResult.value);

    const user = userResult.value ?? { displayName: '', email: '', cpf: null };
    const customerName = input.customerName ?? user.displayName;
    const customerEmail = input.customerEmail?.trim() || user.email?.trim() || undefined;
    const customerTaxId = input.customerTaxId ?? user.cpf;

    if (!customerTaxId) {
      return left(
        new BadRequestError('CPF é obrigatório para pagamento via Checkout. Atualize seu perfil.'),
      );
    }

    const derivedKey = `session:${input.orderId}`;

    const existingResult = await this.transactionRepository.findByOrderId(input.orderId);
    if (existingResult.isLeft()) return left(existingResult.value);

    const existingTx = existingResult.value;

    if (existingTx && existingTx.status !== 'PENDING') {
      return left(new BadRequestError('Order is not payable'));
    }

    if (existingTx?.externalId?.startsWith('pi_')) {
      return left(
        new BadRequestError(
          'A PaymentIntent is already active for this order. Complete it in the app or wait for it to expire.',
        ),
      );
    }

    if (existingTx?.externalId) {
      return right({
        stripeSessionId: existingTx.externalId,
        checkoutUrl: existingTx.checkoutUrl ?? '',
        expiresAt: existingTx.checkoutExpiresAt ?? new Date(),
        orderId: input.orderId,
      });
    }

    const params: PaymentSessionParams = {
      orderId: input.orderId,
      amount: order.amount,
      currency: 'brl',
      customerEmail: customerEmail ?? undefined,
      customerName,
      customerTaxId,
      idempotencyKey: derivedKey,
      transferGroup: `freebay:order:${input.orderId}`,
      successUrl: `${process.env.APP_URL}/payments/success?orderId=${input.orderId}`,
      cancelUrl: `${process.env.APP_URL}/payments/cancel?orderId=${input.orderId}`,
    };

    const sessionResult = await this.paymentProvider.createPaymentSession(params);
    if (sessionResult.isLeft()) {
      this.logger.error(`Payment session failed: ${sessionResult.value.message}`);
      return left(sessionResult.value);
    }

    const session = sessionResult.value;

    const upsertResult = await this.transactionRepository.upsertTransaction({
      orderId: input.orderId,
      externalId: session.stripeSessionId,
      amount: order.amount,
      platformFee: order.platformFee,
      sellerAmount: order.sellerAmount,
      paymentMethod: 'CREDIT_CARD',
      idempotencyKey: derivedKey,
      checkoutUrl: session.checkoutUrl,
      checkoutExpiresAt: session.expiresAt,
    });
    if (upsertResult.isLeft()) return left(upsertResult.value);

    return right({
      stripeSessionId: session.stripeSessionId,
      checkoutUrl: session.checkoutUrl,
      expiresAt: session.expiresAt,
      orderId: input.orderId,
    });
  }
}
