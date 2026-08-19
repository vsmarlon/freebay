import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PaymentProvider, PaymentSessionParams } from '../domain/providers/payment-provider.interface';
import { CreatePaymentSessionInput, CreatePaymentSessionOutput } from '../dtos/payment.dto';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { UserRepository } from '../../auth/domain/repositories/user.repository';
import { TransactionRepository } from '../domain/repositories/transaction.repository';

@Injectable()
export class CreatePaymentSessionUseCase {
  private readonly logger = new Logger(CreatePaymentSessionUseCase.name);

  constructor(
    private readonly orderRepository: OrderRepository,
    private readonly userRepository: UserRepository,
    private readonly transactionRepository: TransactionRepository,
    private readonly paymentProvider: PaymentProvider,
  ) {}

  async execute(
    input: CreatePaymentSessionInput,
  ): Promise<Either<AppError, CreatePaymentSessionOutput>> {
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
    const customerName = input.customerName ?? user.displayName;
    const customerEmail = input.customerEmail ?? user.email;
    const customerTaxId = input.customerTaxId ?? user.cpf;

    // CPF is required for Checkout Session (web/PIX flow)
    if (!customerTaxId) {
      return left(
        new BadRequestError('CPF é obrigatório para pagamento via Checkout. Atualize seu perfil.'),
      );
    }

    // Derived key isolates web Checkout flow from mobile PaymentIntent flow
    const derivedKey = `session:${input.orderId}`;

    const existingResult = await this.transactionRepository.findByDerivedKey(derivedKey);
    if (isLeft(existingResult)) return left(existingResult.value);

    const existingTx = existingResult.value;
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
    if (isLeft(upsertResult)) return left(upsertResult.value);

    return right({
      stripeSessionId: session.stripeSessionId,
      checkoutUrl: session.checkoutUrl,
      expiresAt: session.expiresAt,
      orderId: input.orderId,
    });
  }
}
