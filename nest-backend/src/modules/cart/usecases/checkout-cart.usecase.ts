import { Inject, Injectable, Logger } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { PaymentGroupDatabaseRepository } from '@/modules/payments/data/repositories/payment-group-database.repository';
import { StripeProvider } from '@/modules/payments/providers/stripe-provider';
import { CheckoutCartInput, CheckoutCartOutput, CheckoutMode } from '../dtos/cart.dto';
import { CartDatabaseRepository } from '../data/repositories/cart-database.repository';
import { PRODUCT_UNAVAILABLE } from '../types/cart.types';
import { CheckoutCartPlanner } from './checkout-cart/checkout-cart-planner';
import { CheckoutCartReservation } from './checkout-cart/checkout-cart-reservation';
import { CheckoutCartPayment } from './checkout-cart/checkout-cart-payment';
import { CheckoutCartCompensation } from './checkout-cart/checkout-cart-compensation';

@Injectable()
export class CheckoutCartUseCase {
  private readonly logger = new Logger(CheckoutCartUseCase.name);
  private readonly planner: CheckoutCartPlanner;
  private readonly reservation: CheckoutCartReservation;
  private readonly payment: CheckoutCartPayment;
  private readonly compensation: CheckoutCartCompensation;

  constructor(
    private readonly prisma: PrismaService,
    private readonly cartRepository: CartDatabaseRepository,
    private readonly paymentGroupRepository: PaymentGroupDatabaseRepository,
    private readonly userRepository: UserDatabaseRepository,
    @Inject(StripeProvider) private readonly paymentProvider: StripeProvider,
  ) {
    this.planner = new CheckoutCartPlanner(cartRepository, paymentGroupRepository);
    this.reservation = new CheckoutCartReservation(prisma, cartRepository, paymentGroupRepository);
    this.payment = new CheckoutCartPayment(userRepository, paymentProvider, this.logger);
    this.compensation = new CheckoutCartCompensation(prisma, cartRepository, paymentGroupRepository, this.logger);
  }

  async execute(input: CheckoutCartInput): Promise<Either<AppError, CheckoutCartOutput>> {
    const mode: CheckoutMode = input.mode ?? 'session';
    const planResult = await this.planner.plan(input, mode);
    if (planResult.isLeft()) return left(planResult.value);
    const { cpf, planned, totalAmount, idempotencyKey } = planResult.value;

    const existingResult = await this.planner.findReusable(idempotencyKey);
    if (existingResult.isLeft()) return left(existingResult.value);
    const existing = existingResult.value;
    if (existing && this.planner.isReusable(existing)) return right(this.planner.toOutput(existing));

    let groupId: string;
    let orderIds: Array<{ orderId: string; productId: string }>;
    try {
      const created = await this.reservation.reserve(input.userId, idempotencyKey, totalAmount, planned);
      groupId = created.groupId;
      orderIds = created.reserved;
    } catch (error) {
      if (error instanceof AppError) return left(error);
      if (error instanceof Error && error.message === PRODUCT_UNAVAILABLE) {
        return left(new BadRequestError('Um ou mais produtos não estão mais disponíveis'));
      }
      this.logger.error(
        `Cart checkout transaction failed for user ${input.userId}: ${error instanceof Error ? error.message : String(error)}`,
      );
      return left(new DatabaseError('Erro ao criar pedidos do carrinho'));
    }

    const paymentResult = await this.payment.create(mode, groupId, input.userId, totalAmount, planned, cpf);
    if (paymentResult.isLeft()) {
      await this.compensation.compensate(groupId, orderIds);
      return left(paymentResult.value);
    }

    try {
      await this.prisma.$transaction(async (tx) => {
        const attachResult = await this.paymentGroupRepository.attachPayment(
          { groupId, ...paymentResult.value.attach },
          tx,
        );
        if (attachResult.isLeft()) throw attachResult.value;
        const clearResult = await this.cartRepository.clear(input.userId, tx);
        if (clearResult.isLeft()) throw clearResult.value;
      });
    } catch (error) {
      const payment = paymentResult.value.attach;
      const cancellation = await this.paymentProvider.cancelPendingPayment(
        'stripeSessionId' in payment
          ? { stripeSessionId: payment.stripeSessionId, idempotencyKey: `group-cancel:${groupId}` }
          : 'stripePaymentIntentId' in payment
            ? { stripePaymentIntentId: payment.stripePaymentIntentId, idempotencyKey: `group-cancel:${groupId}` }
            : { idempotencyKey: `group-cancel:${groupId}` },
      );
      if (cancellation.isRight()) {
        await this.compensation.compensate(groupId, orderIds);
      } else {
        this.logger.error(`Payment group ${groupId} remains pending for webhook or expiry reconciliation`);
      }
      if (error instanceof AppError) return left(error);
      this.logger.error(
        `Cart checkout finalization failed for user ${input.userId}: ${error instanceof Error ? error.message : String(error)}`,
      );
      return left(new DatabaseError('Erro ao finalizar pagamento do carrinho'));
    }

    return right({
      paymentGroupId: groupId,
      items: planned.map((item, index) => ({
        orderId: orderIds[index].orderId,
        productId: item.productId,
        productTitle: item.productTitle,
        quantity: item.quantity,
        amount: item.amount,
      })),
      totalOrders: planned.length,
      totalAmount,
      checkoutUrl: paymentResult.value.attach.checkoutUrl ?? null,
      paymentIntentClientSecret: paymentResult.value.attach.clientSecret ?? null,
      expiresAt: paymentResult.value.attach.expiresAt ?? null,
    });
  }
}
