import { Inject, Injectable, Logger } from '@nestjs/common';
import { OrderStatus, PaymentMethod, TransactionStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import {
  AppError,
  NotFoundError,
  BadRequestError,
  InvalidOrderStateError,
  PaymentProviderError,
} from '@/shared/core/errors';
import { PaymentSessionParams } from '../types/payment-provider.types';
import { CHECKOUT_EXPIRY_MILLISECONDS } from '../payment.constants';
import { StripeProvider } from '../providers/stripe-provider';
import { CreatePaymentSessionInput, CreatePaymentSessionOutput } from '../dtos/payment.dto';
import { OrderDatabaseRepository } from '../../orders/data/repositories/order-database.repository';
import { UserDatabaseRepository } from '@/modules/users';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';

@Injectable()
export class CreatePaymentSessionUseCase {
  private readonly logger = new Logger(CreatePaymentSessionUseCase.name);

  constructor(
    private readonly orderRepository: OrderDatabaseRepository,
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

    if (order.status !== OrderStatus.PENDING) {
      return left(new InvalidOrderStateError(OrderStatus.PENDING, order.status));
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

    if (existingTx && existingTx.status !== TransactionStatus.PENDING) {
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

    if (existingTx) {
      return left(new PaymentProviderError('A previous payment attempt requires manual reconciliation'));
    }

    const idempotencyKey = derivedKey;
    const expiresAt = new Date(Date.now() + CHECKOUT_EXPIRY_MILLISECONDS);
    const reserved = await this.transactionRepository.reservePaymentSessionAttempt({
      orderId: input.orderId,
      amount: order.amount,
      platformFee: order.platformFee,
      sellerAmount: order.sellerAmount,
      paymentMethod: PaymentMethod.CREDIT_CARD,
      idempotencyKey,
      expiresAt,
    });
    if (reserved.isLeft()) return left(reserved.value);
    if (!reserved.value) {
      return left(new PaymentProviderError('A payment attempt already exists and requires reconciliation'));
    }

    const params: PaymentSessionParams = {
      orderId: input.orderId,
      buyerId: order.buyerId,
      amount: order.amount,
      currency: 'brl',
      customerEmail: customerEmail ?? undefined,
      customerName,
      customerTaxId,
      idempotencyKey,
      expiresAt,
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
    const canonicalResult = await this.paymentProvider.retrievePaymentSession(session.stripeSessionId);
    if (canonicalResult.isLeft()) return left(canonicalResult.value);
    const canonical = canonicalResult.value;
    if (
      canonical.stripeSessionId !== session.stripeSessionId ||
      canonical.mode !== 'payment' ||
      (canonical.status !== 'open' && canonical.status !== 'complete') ||
      canonical.amountTotal !== order.amount ||
      canonical.currency?.toLowerCase() !== 'brl' ||
      canonical.orderId !== order.id ||
      canonical.paymentGroupId !== null ||
      canonical.buyerId !== order.buyerId ||
      canonical.idempotencyKey !== idempotencyKey ||
      !canonical.expiresAt
    ) {
      return left(new PaymentProviderError('Checkout Session does not match the durable order attempt'));
    }

    const attached = await this.transactionRepository.attachPaymentSession({
      orderId: input.orderId,
      idempotencyKey,
      externalId: canonical.stripeSessionId,
      checkoutUrl: canonical.checkoutUrl ?? '',
      expiresAt: canonical.expiresAt,
    });
    if (attached.isLeft()) return left(attached.value);
    if (!attached.value) return left(new PaymentProviderError('Checkout Session could not be attached to its durable attempt'));

    return right({
      stripeSessionId: canonical.stripeSessionId,
      checkoutUrl: canonical.checkoutUrl ?? '',
      expiresAt: canonical.expiresAt,
      orderId: input.orderId,
    });
  }
}
