import { Injectable, Logger } from '@nestjs/common';
import { createHash } from 'node:crypto';
import { Prisma } from '@prisma/client';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError, DatabaseError } from '@/shared/core/errors';
import { splitAmount } from '@/shared/core/platform-fee';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { PaymentGroupRepository } from '@/modules/payments/domain/repositories/payment-group.repository';
import {
  PaymentLineItem,
  PaymentProvider,
} from '@/modules/payments/domain/providers/payment-provider.interface';
import { PaymentGroupSnapshot } from '@/modules/payments/types/payment-group.types';
import { CartRepository } from '../domain/repositories/cart.repository';
import { PRODUCT_UNAVAILABLE, ReserveOrderInput } from '../types/cart.types';
import {
  CheckoutCartInput,
  CheckoutCartItemOutput,
  CheckoutCartOutput,
  CheckoutMode,
} from '../dtos/cart.dto';

const CHECKOUT_WINDOW_MS = 3600 * 1000;

interface PlannedItem extends ReserveOrderInput {
  productTitle: string;
}

@Injectable()
export class CheckoutCartUseCase {
  private readonly logger = new Logger(CheckoutCartUseCase.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly cartRepository: CartRepository,
    private readonly paymentGroupRepository: PaymentGroupRepository,
    private readonly userRepository: UserRepository,
    private readonly paymentProvider: PaymentProvider,
  ) {}

  async execute(input: CheckoutCartInput): Promise<Either<AppError, CheckoutCartOutput>> {
    const mode: CheckoutMode = input.mode ?? 'session';

    const cpfResult = await this.cartRepository.findUserCpf(input.userId);
    if (isLeft(cpfResult)) return left(cpfResult.value);
    if (mode === 'session' && !cpfResult.value) {
      return left(new BadRequestError('Adicione seu CPF no perfil antes de realizar uma compra'));
    }

    const cartResult = await this.cartRepository.getUserCart(input.userId);
    if (isLeft(cartResult)) return left(cartResult.value);

    const cartItems = cartResult.value;
    if (cartItems.length === 0) {
      return left(new BadRequestError('Carrinho vazio'));
    }

    const planned: PlannedItem[] = [];
    for (const item of cartItems) {
      if (item.product.sellerId === input.userId) {
        return left(new BadRequestError('Você não pode comprar seu próprio produto'));
      }
      if (item.product.status !== 'ACTIVE') {
        return left(new BadRequestError('Um ou mais produtos do carrinho não estão disponíveis'));
      }

      const availableStock = Math.max(item.product.quantity - item.product.soldCount, 0);
      if (item.quantity < 1 || item.quantity > availableStock) {
        return left(new BadRequestError(`Estoque insuficiente para ${item.product.title}`));
      }

      const amount = item.product.price * item.quantity;
      const { platformFee, sellerAmount } = splitAmount(amount);

      planned.push({
        userId: input.userId,
        sellerId: item.product.sellerId,
        productId: item.productId,
        productTitle: item.product.title,
        quantity: item.quantity,
        amount,
        platformFee,
        sellerAmount,
      });
    }

    const totalAmount = planned.reduce((sum, item) => sum + item.amount, 0);
    const idempotencyKey = this.buildIdempotencyKey(input.userId, planned, mode);

    const existingResult = await this.paymentGroupRepository.findByIdempotencyKey(idempotencyKey);
    if (isLeft(existingResult)) return left(existingResult.value);

    const existing = existingResult.value;
    if (existing && this.isReusable(existing)) {
      return right(this.toOutput(existing));
    }

    let groupId: string;
    let orderIds: Array<{ orderId: string; productId: string }>;
    try {
      const created = await this.prisma.$transaction(async (tx) => {
        const reserved: Array<{ orderId: string; productId: string }> = [];
        for (const item of planned) {
          const order = await this.cartRepository.reserveAndCreateOrder(item, tx);
          reserved.push({ orderId: order.id, productId: item.productId });
        }

        const group = await this.paymentGroupRepository.create(
          {
            buyerId: input.userId,
            amount: totalAmount,
            currency: 'brl',
            idempotencyKey,
            expiresAt: new Date(Date.now() + CHECKOUT_WINDOW_MS),
            orders: reserved.map((entry, index) => ({
              orderId: entry.orderId,
              amount: planned[index].amount,
              platformFee: planned[index].platformFee,
              sellerAmount: planned[index].sellerAmount,
            })),
          },
          tx,
        );

        const clearResult = await this.cartRepository.clear(input.userId, tx);
        if (isLeft(clearResult)) throw clearResult.value;

        return { groupId: group.id, reserved };
      });

      groupId = created.groupId;
      orderIds = created.reserved;
    } catch (error) {
      if (error instanceof AppError) return left(error);
      if ((error as Error).message === PRODUCT_UNAVAILABLE) {
        return left(new BadRequestError('Um ou mais produtos não estão mais disponíveis'));
      }
      this.logger.error(
        `Cart checkout transaction failed for user ${input.userId}: ${(error as Error).message}`,
      );
      return left(new DatabaseError('Erro ao criar pedidos do carrinho'));
    }

    const paymentResult =
      mode === 'session'
        ? await this.createSession(groupId, input.userId, totalAmount, planned, cpfResult.value)
        : await this.createIntent(groupId, input.userId, totalAmount);

    if (isLeft(paymentResult)) {
      await this.compensate(groupId, orderIds);
      return left(paymentResult.value);
    }

    const attachResult = await this.paymentGroupRepository.attachPayment({
      groupId,
      ...paymentResult.value.attach,
    });
    if (isLeft(attachResult)) {
      await this.compensate(groupId, orderIds);
      return left(attachResult.value);
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

  private async createSession(
    groupId: string,
    userId: string,
    amount: number,
    planned: PlannedItem[],
    customerTaxId: string | null,
  ): Promise<
    Either<
      AppError,
      {
        attach: {
          stripeSessionId?: string;
          checkoutUrl?: string;
          expiresAt?: Date;
          clientSecret?: string;
        };
      }
    >
  > {
    const userResult = await this.userRepository.findPaymentInfo(userId);
    if (isLeft(userResult)) return left(userResult.value);
    const user = userResult.value ?? { displayName: '', email: '', cpf: null };

    const lineItems: PaymentLineItem[] = planned.map((item) => ({
      name: item.productTitle,
      amount: item.amount / item.quantity,
      quantity: item.quantity,
    }));

    const sessionResult = await this.paymentProvider.createPaymentSession({
      paymentGroupId: groupId,
      amount,
      currency: 'brl',
      customerEmail: user.email ?? undefined,
      customerName: user.displayName,
      customerTaxId: customerTaxId ?? undefined,
      idempotencyKey: `group-session:${groupId}`,
      lineItems,
      successUrl: `${process.env.APP_URL}/payments/success?paymentGroupId=${groupId}`,
      cancelUrl: `${process.env.APP_URL}/payments/cancel?paymentGroupId=${groupId}`,
    });
    if (isLeft(sessionResult)) {
      this.logger.error(`Cart payment session failed: ${sessionResult.value.message}`);
      return left(sessionResult.value);
    }

    return right({
      attach: {
        stripeSessionId: sessionResult.value.stripeSessionId,
        checkoutUrl: sessionResult.value.checkoutUrl,
        expiresAt: sessionResult.value.expiresAt,
      },
    });
  }

  private async createIntent(
    groupId: string,
    userId: string,
    amount: number,
  ): Promise<
    Either<
      AppError,
      {
        attach: {
          stripePaymentIntentId?: string;
          clientSecret?: string;
          expiresAt?: Date;
          checkoutUrl?: string;
        };
      }
    >
  > {
    const userResult = await this.userRepository.findPaymentInfo(userId);
    if (isLeft(userResult)) return left(userResult.value);
    const user = userResult.value ?? { displayName: '', email: '', cpf: null };

    const intentResult = await this.paymentProvider.createPaymentIntent({
      paymentGroupId: groupId,
      amount,
      currency: 'brl',
      receiptEmail: user.email ?? undefined,
      idempotencyKey: `group-pi:${groupId}`,
    });
    if (isLeft(intentResult)) {
      this.logger.error(`Cart payment intent failed: ${intentResult.value.message}`);
      return left(intentResult.value);
    }

    return right({
      attach: {
        stripePaymentIntentId: intentResult.value.paymentIntentId,
        clientSecret: intentResult.value.clientSecret,
      },
    });
  }

  private async compensate(
    groupId: string,
    orders: Array<{ orderId: string; productId: string }>,
  ): Promise<void> {
    try {
      await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
        for (const entry of orders) {
          await this.cartRepository.restoreOrderReservation(entry.orderId, entry.productId, tx);
        }
        await this.paymentGroupRepository.markTerminal(groupId, 'FAILED', tx);
      });
    } catch (error) {
      this.logger.error(
        `Failed to compensate cart checkout group ${groupId}: ${(error as Error).message}. The checkout expiry job will reclaim it.`,
      );
    }
  }

  private buildIdempotencyKey(
    userId: string,
    planned: PlannedItem[],
    mode: CheckoutMode,
  ): string {
    const fingerprint = planned
      .map((item) => `${item.productId}:${item.quantity}:${item.amount}`)
      .sort()
      .join('|');
    const digest = createHash('sha256').update(fingerprint).digest('hex').slice(0, 32);
    return `cart:${userId}:${mode}:${digest}`;
  }

  private isReusable(group: PaymentGroupSnapshot): boolean {
    if (group.status !== 'PENDING') return false;
    if (!group.expiresAt) return false;
    if (group.expiresAt.getTime() <= Date.now()) return false;
    return Boolean(group.checkoutUrl || group.clientSecret);
  }

  private toOutput(group: PaymentGroupSnapshot): CheckoutCartOutput {
    const items: CheckoutCartItemOutput[] = group.orders.map((order) => ({
      orderId: order.orderId,
      productId: order.productId,
      productTitle: order.productTitle,
      quantity: order.quantity,
      amount: order.amount,
    }));

    return {
      paymentGroupId: group.id,
      items,
      totalOrders: items.length,
      totalAmount: group.amount,
      checkoutUrl: group.checkoutUrl,
      paymentIntentClientSecret: group.clientSecret,
      expiresAt: group.expiresAt,
    };
  }
}
