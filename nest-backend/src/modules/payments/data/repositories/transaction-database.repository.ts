import { Injectable } from '@nestjs/common';
import { Prisma, Transaction, TransferDeliveryState, ReversalState } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, encodeCursor, MAX_PAGE_SIZE, DEFAULT_PAGE_SIZE } from '@/shared/core/pagination';
import { ConflictError } from '@/shared/core/errors';
import {
  ExpiredPendingTransaction,
  TransactionWithOrder,
  UpsertTransactionData,
} from '../../types/payment.types';

@Injectable()
export class TransactionDatabaseRepository extends BasePrismaRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async markAsPaid(
    id: string,
    chargeId: string | null,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const client = tx ?? this.prisma;
      const result = await client.transaction.updateMany({
        where: { id, status: 'PENDING' },
        data: { status: 'PAID', paidAt: new Date(), ...(chargeId ? { chargeId } : {}) },
      });
      return { count: result.count };
    }, 'Failed to mark transaction as paid');
  }

  async setChargeId(
    orderId: string,
    chargeId: string,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<void> {
    return this.safeRun(async () => {
      const client = tx ?? this.prisma;
      await client.transaction.updateMany({
        where: { orderId, chargeId: null },
        data: { chargeId },
      });
    }, 'Failed to persist charge id');
  }

  async claimTransfer(
    orderId: string,
    processingAt: Date,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const client = tx ?? this.prisma;
      const result = await client.transaction.updateMany({
        where: {
          orderId,
          transferState: {
            in: ['PENDING', 'RETRYABLE'],
          },
        },
        data: { transferState: TransferDeliveryState.PROCESSING, transferProcessingAt: processingAt, transferAttempts: { increment: 1 } },
      });
      return { count: result.count };
    }, 'Failed to claim transfer');
  }

  async reclaimStaleTransfer(
    cutoff: Date,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const result = await (tx ?? this.prisma).transaction.updateMany({
        where: { transferState: 'PROCESSING', transferProcessingAt: { lt: cutoff } },
        data: { transferState: 'RETRYABLE', transferLastError: 'Processing lease expired' },
      });
      return { count: result.count };
    }, 'Failed to reclaim stale transfers');
  }

  async finalizeTransfer(
    id: string,
    transferId: string,
    tx: Prisma.TransactionClient,
  ): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const result = await tx.transaction.updateMany({
        where: { id, transferState: 'PROCESSING', transferId: null },
        data: { transferId, transferState: 'SUCCEEDED', reversalState: 'PENDING', transferProcessingAt: null, transferLastError: null, releasedAt: new Date() },
      });
      return { count: result.count };
    }, 'Failed to finalize transfer');
  }

  async markTransferFailure(
    id: string,
    state: Extract<TransferDeliveryState, 'RETRYABLE' | 'TERMINAL'>,
    error: string,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const result = await (tx ?? this.prisma).transaction.updateMany({
        where: { id, transferState: 'PROCESSING' },
        data: { transferState: state, transferProcessingAt: null, transferLastError: error },
      });
      return { count: result.count };
    }, 'Failed to persist transfer failure');
  }

  async claimReversal(orderId: string, processingAt: Date, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const result = await (tx ?? this.prisma).transaction.updateMany({
        where: { orderId, transferId: { not: null }, reversalState: { in: ['PENDING', 'RETRYABLE'] } },
        data: { reversalState: ReversalState.PROCESSING, reversalProcessingAt: processingAt, reversalAttempts: { increment: 1 } },
      });
      return { count: result.count };
    }, 'Failed to claim reversal');
  }

  async finalizeReversal(id: string, reversalId: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const result = await (tx ?? this.prisma).transaction.updateMany({
        where: { id, reversalState: 'PROCESSING', reversalId: null },
        data: { reversalId, reversalState: 'SUCCEEDED', reversalProcessingAt: null, reversalLastError: null },
      });
      return { count: result.count };
    }, 'Failed to finalize reversal');
  }

  async markReversalFailure(id: string, state: Extract<ReversalState, 'RETRYABLE' | 'TERMINAL'>, error: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const result = await (tx ?? this.prisma).transaction.updateMany({
        where: { id, reversalState: 'PROCESSING' },
        data: { reversalState: state, reversalProcessingAt: null, reversalLastError: error },
      });
      return { count: result.count };
    }, 'Failed to persist reversal failure');
  }

  async reclaimStaleReversal(cutoff: Date, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const result = await (tx ?? this.prisma).transaction.updateMany({
        where: { reversalState: 'PROCESSING', reversalProcessingAt: { lt: cutoff } },
        data: { reversalState: 'RETRYABLE', reversalLastError: 'Processing lease expired' },
      });
      return { count: result.count };
    }, 'Failed to reclaim stale reversals');
  }

  async findTransferFailures(
    cursor: { updatedAt: Date; id: string } | null = null,
    limit = DEFAULT_PAGE_SIZE,
  ): RepositoryResponse<CursorPage<TransactionWithOrder>> {
    return this.safeRun(async () => {
      const pageLimit = Math.min(Math.max(limit, 1), MAX_PAGE_SIZE);
      const rows = await this.prisma.transaction.findMany({
        where: {
          OR: [
            { transferState: { in: ['PROCESSING', 'RETRYABLE', 'TERMINAL'] } },
            { reversalState: { in: ['PROCESSING', 'RETRYABLE', 'TERMINAL'] } },
          ],
          ...(cursor ? {
            AND: [{ OR: [
              { updatedAt: { lt: cursor.updatedAt } },
              { updatedAt: cursor.updatedAt, id: { lt: cursor.id } },
            ] }],
          } : {}),
        },
        include: {
          order: {
            include: {
              buyer: { select: { id: true, displayName: true } },
              seller: { select: { id: true, displayName: true } },
            },
          },
        },
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        take: pageLimit + 1,
      });
      const hasMore = rows.length > pageLimit;
      const items = hasMore ? rows.slice(0, pageLimit) : rows;
      const last = items[items.length - 1];
      return {
        items: items as TransactionWithOrder[],
        hasMore,
        nextCursor: hasMore && last
          ? encodeCursor({ updatedAt: last.updatedAt.toISOString(), id: last.id })
          : null,
      };
    }, 'Failed to list transfer failures');
  }

  async markAsFailed(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return this.safeRun(async () => {
      const client = tx ?? this.prisma;
      const result = await client.transaction.updateMany({
        where: { id, status: 'PENDING' },
        data: { status: 'FAILED' },
      });
      return { count: result.count };
    }, 'Failed to mark transaction as failed');
  }

  async findByIdempotencyKey(key: string): RepositoryResponse<TransactionWithOrder | null> {
    return this.safeRun(async () => {
      const transaction = await this.prisma.transaction.findFirst({
        where: { idempotencyKey: key },
        include: {
          order: {
            include: {
              buyer: { select: { id: true, displayName: true } },
              seller: { select: { id: true, displayName: true } },
            },
          },
        },
      });
      return transaction as TransactionWithOrder | null;
    }, 'Failed to find transaction');
  }

  async findByChargeId(chargeId: string): RepositoryResponse<TransactionWithOrder | null> {
    return this.safeRun(async () => {
      const transaction = await this.prisma.transaction.findFirst({
        where: { chargeId },
        include: {
          order: {
            include: {
              buyer: { select: { id: true, displayName: true } },
              seller: { select: { id: true, displayName: true } },
            },
          },
        },
      });
      return transaction as TransactionWithOrder | null;
    }, 'Erro ao buscar transação por charge');
  }

  async findByOrderId(orderId: string): RepositoryResponse<TransactionWithOrder | null> {
    return this.safeRun(async () => {
      const transaction = await this.prisma.transaction.findUnique({
        where: { orderId },
        include: {
          order: {
            include: {
              buyer: { select: { id: true, displayName: true } },
              seller: { select: { id: true, displayName: true } },
            },
          },
        },
      });
      return transaction as TransactionWithOrder | null;
    }, 'Failed to find transaction by order id');
  }

  async findByDerivedKey(key: string): RepositoryResponse<Transaction | null> {
    return this.safeRun(() => this.prisma.transaction.findFirst({
      where: { idempotencyKey: key },
    }), 'Failed to find transaction by key');
  }

  async findExpiredPending(now: Date): RepositoryResponse<ExpiredPendingTransaction[]> {
    return this.safeRun(async () => {
      const transactions = await this.prisma.transaction.findMany({
        where: {
          status: 'PENDING',
          paymentGroupId: null,
          checkoutExpiresAt: { lt: now },
          order: { status: 'PENDING' },
        },
        select: {
          id: true,
          orderId: true,
          order: { select: { productId: true, quantity: true } },
        },
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
    return this.safeRun(async () => {
      const claimed = await this.prisma.transaction.updateMany({
        where: { orderId: data.orderId, status: 'PENDING' },
        data: {
          externalId: data.externalId,
          idempotencyKey: data.idempotencyKey,
          checkoutUrl: data.checkoutUrl ?? undefined,
          checkoutExpiresAt: data.checkoutExpiresAt ?? undefined,
        },
      });
      if (claimed.count > 0) return;

      const settled = await this.prisma.transaction.findUnique({
        where: { orderId: data.orderId },
        select: { status: true },
      });
      if (settled) {
        throw new ConflictError(
          `Transação do pedido ${data.orderId} está em ${settled.status} e não pode voltar para PENDING`,
        );
      }

      await this.prisma.transaction.create({
        data: {
          order: { connect: { id: data.orderId } },
          externalId: data.externalId,
          amount: data.amount,
          platformFee: data.platformFee,
          sellerAmount: data.sellerAmount,
          paymentMethod: data.paymentMethod,
          provider: 'STRIPE',
          status: 'PENDING',
          idempotencyKey: data.idempotencyKey,
          checkoutUrl: data.checkoutUrl,
          checkoutExpiresAt: data.checkoutExpiresAt,
        },
      });
    }, 'Failed to upsert transaction');
  }
}
