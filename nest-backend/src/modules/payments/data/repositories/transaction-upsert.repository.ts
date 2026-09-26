import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { OrderStatus, PaymentProvider, TransactionStatus } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse } from '@/shared/core/either';
import { ConflictError } from '@/shared/core/errors';
import { ExpiredPendingTransaction, UpsertTransactionData } from '../../types/payment.types';

export class TransactionUpsertRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findExpiredPending(now: Date): RepositoryResponse<ExpiredPendingTransaction[]> {
    return repositoryResponse(async () => {
      const transactions = await this.prisma.transaction.findMany({
        where: { status: TransactionStatus.PENDING, paymentGroupId: null, checkoutExpiresAt: { lt: now }, order: { status: OrderStatus.PENDING } },
        select: { id: true, orderId: true, order: { select: { productId: true, quantity: true } } },
      });
      return transactions.map((transaction) => ({
        id: transaction.id,
        orderId: transaction.orderId,
        productId: transaction.order.productId,
        quantity: transaction.order.quantity,
      }));
    }, 'Failed to find expired transactions');
  }

  async upsertTransaction(data: UpsertTransactionData): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      const claimed = await this.prisma.transaction.updateMany({
        where: { orderId: data.orderId, status: TransactionStatus.PENDING },
        data: {
          externalId: data.externalId,
          idempotencyKey: data.idempotencyKey,
          checkoutUrl: data.checkoutUrl ?? undefined,
          checkoutExpiresAt: data.checkoutExpiresAt ?? undefined,
        },
      });
      if (claimed.count > 0) return;

      const settled = await this.prisma.transaction.findUnique({ where: { orderId: data.orderId }, select: { status: true } });
      if (settled) {
        throw new ConflictError(`Transação do pedido ${data.orderId} está em ${settled.status} e não pode voltar para PENDING`);
      }

      await this.prisma.transaction.create({
        data: {
          order: { connect: { id: data.orderId } },
          externalId: data.externalId,
          amount: data.amount,
          platformFee: data.platformFee,
          sellerAmount: data.sellerAmount,
          paymentMethod: data.paymentMethod,
          provider: PaymentProvider.STRIPE,
          status: TransactionStatus.PENDING,
          idempotencyKey: data.idempotencyKey,
          checkoutUrl: data.checkoutUrl,
          checkoutExpiresAt: data.checkoutExpiresAt,
        },
      });
    }, 'Failed to upsert transaction');
  }
}
