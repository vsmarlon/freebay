import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import {
  AttachGroupPaymentInput,
  CreatePaymentGroupInput,
  PaymentGroupSnapshot,
} from '../../types/payment-group.types';

const GROUP_INCLUDE = {
  transactions: {
    select: {
      id: true,
      orderId: true,
      amount: true,
      sellerAmount: true,
      status: true,
      order: {
        select: {
          buyerId: true,
          sellerId: true,
          productId: true,
          quantity: true,
          product: { select: { title: true } },
        },
      },
    },
  },
} satisfies Prisma.PaymentGroupInclude;

type GroupPayload = Prisma.PaymentGroupGetPayload<{ include: typeof GROUP_INCLUDE }>;

@Injectable()
export class PaymentGroupDatabaseRepository
  extends BasePrismaRepository
{
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(
    data: CreatePaymentGroupInput,
    tx: Prisma.TransactionClient,
  ): Promise<{ id: string }> {
    const group = await tx.paymentGroup.create({
      data: {
        buyerId: data.buyerId,
        amount: data.amount,
        currency: data.currency,
        provider: 'STRIPE',
        idempotencyKey: data.idempotencyKey,
        expiresAt: data.expiresAt,
      },
      select: { id: true },
    });

    for (const order of data.orders) {
      await tx.transaction.create({
        data: {
          orderId: order.orderId,
          amount: order.amount,
          platformFee: order.platformFee,
          sellerAmount: order.sellerAmount,
          paymentMethod: 'CREDIT_CARD',
          provider: 'STRIPE',
          status: 'PENDING',
          idempotencyKey: `group:${group.id}:${order.orderId}`,
          checkoutExpiresAt: data.expiresAt,
          paymentGroupId: group.id,
        },
      });
    }

    return group;
  }

  async findById(groupId: string): RepositoryResponse<PaymentGroupSnapshot | null> {
    return this.safeRun(async () => {
      const group = await this.prisma.paymentGroup.findUnique({
        where: { id: groupId },
        include: GROUP_INCLUDE,
      });
      return group ? this.toSnapshot(group) : null;
    }, 'Erro ao buscar pagamento do carrinho');
  }

  async findByIdempotencyKey(
    idempotencyKey: string,
  ): RepositoryResponse<PaymentGroupSnapshot | null> {
    return this.safeRun(async () => {
      const group = await this.prisma.paymentGroup.findUnique({
        where: { idempotencyKey },
        include: GROUP_INCLUDE,
      });
      return group ? this.toSnapshot(group) : null;
    }, 'Erro ao buscar pagamento do carrinho');
  }

  async attachPayment(data: AttachGroupPaymentInput): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.$transaction(async (tx) => {
        await tx.paymentGroup.update({
          where: { id: data.groupId },
          data: {
            stripePaymentIntentId: data.stripePaymentIntentId ?? undefined,
            stripeSessionId: data.stripeSessionId ?? undefined,
            clientSecret: data.clientSecret ?? undefined,
            checkoutUrl: data.checkoutUrl ?? undefined,
            expiresAt: data.expiresAt ?? undefined,
          },
        });

        const externalId = data.stripePaymentIntentId ?? data.stripeSessionId;
        await tx.transaction.updateMany({
          where: { paymentGroupId: data.groupId },
          data: {
            externalId: externalId ?? undefined,
            checkoutUrl: data.checkoutUrl ?? undefined,
            checkoutExpiresAt: data.expiresAt ?? undefined,
          },
        });
      });
    }, 'Erro ao vincular pagamento ao carrinho');
  }

  async claimPaid(
    groupId: string,
    chargeId: string | null,
    tx: Prisma.TransactionClient,
  ): Promise<number> {
    const claimed = await tx.paymentGroup.updateMany({
      where: { id: groupId, status: 'PENDING' },
      data: { status: 'PAID', paidAt: new Date(), chargeId },
    });
    return claimed.count;
  }

  async markTerminal(
    groupId: string,
    status: 'FAILED' | 'EXPIRED',
    tx: Prisma.TransactionClient,
  ): Promise<number> {
    const claimed = await tx.paymentGroup.updateMany({
      where: { id: groupId, status: 'PENDING' },
      data: { status },
    });
    return claimed.count;
  }

  async findExpiredGroupIds(now: Date): RepositoryResponse<string[]> {
    return this.safeRun(async () => {
      const groups = await this.prisma.paymentGroup.findMany({
        where: { status: 'PENDING', expiresAt: { lt: now } },
        select: { id: true },
      });
      return groups.map((group) => group.id);
    }, 'Erro ao buscar pagamentos expirados');
  }

  private toSnapshot(group: GroupPayload): PaymentGroupSnapshot {
    return {
      id: group.id,
      buyerId: group.buyerId,
      amount: group.amount,
      currency: group.currency,
      status: group.status,
      stripePaymentIntentId: group.stripePaymentIntentId,
      stripeSessionId: group.stripeSessionId,
      clientSecret: group.clientSecret,
      checkoutUrl: group.checkoutUrl,
      expiresAt: group.expiresAt,
      orders: group.transactions.map((transaction) => ({
        orderId: transaction.orderId,
        transactionId: transaction.id,
        transactionStatus: transaction.status,
        amount: transaction.amount,
        sellerAmount: transaction.sellerAmount,
        buyerId: transaction.order.buyerId,
        sellerId: transaction.order.sellerId,
        productId: transaction.order.productId,
        productTitle: transaction.order.product.title,
        quantity: transaction.order.quantity,
      })),
    };
  }
}
