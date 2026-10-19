import { Prisma, TransactionStatus, TransferDeliveryState, ReversalState } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse } from '@/shared/core/either';
import { ConflictError, NotFoundError } from '@/shared/core/errors';
import { CursorPage, encodeCursor, MAX_PAGE_SIZE, DEFAULT_PAGE_SIZE } from '@/shared/core/pagination';
import {
  TransactionWithOrder,
  TRANSACTION_WITH_ORDER_INCLUDE,
} from '../../types/payment.types';
import { ChargeRefundSnapshot } from '../../types/payment-provider.types';

export interface RefundReservation {
  operationId: string;
  idempotencyKey: string;
  providerId: string | null;
  created: boolean;
}

export class TransactionReconciliationRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findTransferFailures(cursor: { updatedAt: Date; id: string } | null = null, limit = DEFAULT_PAGE_SIZE): RepositoryResponse<CursorPage<TransactionWithOrder>> {
    return repositoryResponse(async () => {
      const pageLimit = Math.min(Math.max(limit, 1), MAX_PAGE_SIZE);
      const rows = await this.prisma.transaction.findMany({
        where: {
          OR: [
            { transferState: { in: [TransferDeliveryState.PROCESSING, TransferDeliveryState.RETRYABLE, TransferDeliveryState.TERMINAL] } },
            { reversalState: { in: [ReversalState.PROCESSING, ReversalState.RETRYABLE, ReversalState.TERMINAL] } },
          ],
          ...(cursor ? { AND: [{ OR: [
            { updatedAt: { lt: cursor.updatedAt } },
            { updatedAt: cursor.updatedAt, id: { lt: cursor.id } },
          ] }] } : {}),
        },
        include: TRANSACTION_WITH_ORDER_INCLUDE,
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        take: pageLimit + 1,
      });
      const hasMore = rows.length > pageLimit;
      const items = hasMore ? rows.slice(0, pageLimit) : rows;
      const last = items[items.length - 1];
      return {
        items,
        hasMore,
        nextCursor: hasMore && last ? encodeCursor({ updatedAt: last.updatedAt.toISOString(), id: last.id }) : null,
      };
    }, 'Failed to list transfer failures');
  }

  async markAsFailed(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => {
      const result = await (tx ?? this.prisma).transaction.updateMany({ where: { id, status: TransactionStatus.PENDING }, data: { status: TransactionStatus.FAILED } });
      return { count: result.count };
    }, 'Failed to mark transaction as failed');
  }

  async findByIdempotencyKey(key: string): RepositoryResponse<TransactionWithOrder | null> {
    return this.findOne({ idempotencyKey: key }, 'Failed to find transaction');
  }

  async findByChargeId(chargeId: string): RepositoryResponse<TransactionWithOrder | null> {
    return this.findOne({ chargeId }, 'Erro ao buscar transação por charge');
  }

  async findByOrderId(orderId: string): RepositoryResponse<TransactionWithOrder | null> {
    return repositoryResponse(async () => {
      return this.prisma.transaction.findUnique({
        where: { orderId },
        include: TRANSACTION_WITH_ORDER_INCLUDE,
      });
    }, 'Failed to find transaction by order id');
  }

  async findPendingRefundRecoveries(): RepositoryResponse<Array<{ orderId: string; chargeId: string; refundProviderId: string | null }>> {
    return repositoryResponse(async () => this.prisma.transaction.findMany({
      where: {
        refundOperationId: { not: null },
        chargeId: { not: null },
        status: { in: [TransactionStatus.PAID, TransactionStatus.HELD, TransactionStatus.RELEASED] },
      },
      select: { orderId: true, chargeId: true, refundProviderId: true },
      orderBy: { updatedAt: 'asc' },
    }).then((rows) => rows.flatMap((row) => row.chargeId
      ? [{ orderId: row.orderId, chargeId: row.chargeId, refundProviderId: row.refundProviderId }]
      : [])), 'Failed to list refund recoveries');
  }

  async reserveRefund(orderId: string, amount: number, provider: ChargeRefundSnapshot): RepositoryResponse<RefundReservation> {
    return repositoryResponse(async () => this.prisma.$transaction(async (tx) => {
      const current = await tx.transaction.findUnique({ where: { orderId } });
      if (!current) throw new NotFoundError('Transaction');
      if (current.paymentGroupId) {
        await tx.$queryRaw<Array<{ id: string }>>(Prisma.sql`SELECT "id" FROM "PaymentGroup" WHERE "id" = ${current.paymentGroupId} FOR UPDATE`);
      } else {
        await tx.$queryRaw<Array<{ id: string }>>(Prisma.sql`SELECT "id" FROM "Transaction" WHERE "id" = ${current.id} FOR UPDATE`);
      }
      const locked = await tx.transaction.findUnique({ where: { id: current.id } });
      if (!locked) throw new NotFoundError('Transaction');
      const rows = locked.paymentGroupId
        ? await tx.transaction.findMany({
            where: { paymentGroupId: locked.paymentGroupId, refundAmount: { not: null } },
            select: { id: true, orderId: true, refundAmount: true, refundOperationId: true, refundProviderId: true },
          })
        : await tx.transaction.findMany({
            where: { id: locked.id, refundAmount: { not: null } },
            select: { id: true, orderId: true, refundAmount: true, refundOperationId: true, refundProviderId: true },
          });
      const allocationTotal = rows.reduce((sum, row) => sum + (row.refundAmount ?? 0), 0);
      const reflectedTotal = rows.reduce((sum, row) => {
        const matches = row.refundOperationId
          ? provider.refunds.filter((item) => item.operationId === row.refundOperationId)
          : [];
        if (matches.length > 1) throw new ConflictError('Mais de um reembolso Stripe corresponde à mesma operação');
        const match = matches[0];
        if (match && (
          match.orderId !== row.orderId ||
          match.chargeId !== provider.id ||
          match.amount !== row.refundAmount ||
          (row.refundProviderId !== null && match.id !== row.refundProviderId)
        )) throw new ConflictError('O reembolso canônico não corresponde à alocação persistida');
        return sum + (match?.amount ?? 0);
      }, 0);
      const externalRefunded = provider.amountRefunded - reflectedTotal;
      if (!Number.isInteger(amount) || amount <= 0 || externalRefunded < 0 ||
        allocationTotal + externalRefunded + (locked.refundAmount === null ? amount : 0) > provider.amount) {
        throw new ConflictError('Reembolso excede o valor disponível da cobrança');
      }

      if (locked.refundOperationId && locked.refundIdempotencyKey && locked.refundAmount === amount) {
        return {
          operationId: locked.refundOperationId,
          idempotencyKey: locked.refundIdempotencyKey,
          providerId: locked.refundProviderId,
          created: false,
        };
      }
      if (locked.refundOperationId || locked.refundAmount !== null || locked.refundIdempotencyKey) {
        throw new ConflictError('Operação de reembolso exige reconciliação');
      }

      const operationId = randomUUID();
      const idempotencyKey = `freebay-refund-${locked.id}`;
      const saved = await tx.transaction.updateMany({
        where: { id: locked.id, refundOperationId: null, refundAmount: null },
        data: { refundOperationId: operationId, refundIdempotencyKey: idempotencyKey, refundAmount: amount },
      });
      if (saved.count === 0) throw new ConflictError('Operação de reembolso reivindicada por outra solicitação');
      return { operationId, idempotencyKey, providerId: null, created: true };
    }), 'Failed to reserve refund allocation');
  }

  async recordRefundProviderId(orderId: string, operationId: string, refundId: string): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const saved = await this.prisma.transaction.updateMany({
        where: { orderId, refundOperationId: operationId, OR: [{ refundProviderId: null }, { refundProviderId: refundId }] },
        data: { refundProviderId: refundId },
      });
      return saved.count > 0;
    }, 'Failed to record provider refund id');
  }

  private async findOne(where: Prisma.TransactionWhereInput, errorMessage: string): RepositoryResponse<TransactionWithOrder | null> {
    return repositoryResponse(async () => {
      return this.prisma.transaction.findFirst({
        where,
        include: TRANSACTION_WITH_ORDER_INCLUDE,
      });
    }, errorMessage);
  }
}
