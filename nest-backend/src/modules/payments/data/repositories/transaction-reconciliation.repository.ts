import { Prisma, TransactionStatus, TransferDeliveryState, ReversalState } from '@prisma/client';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, encodeCursor, MAX_PAGE_SIZE, DEFAULT_PAGE_SIZE } from '@/shared/core/pagination';
import {
  TransactionWithOrder,
  TRANSACTION_WITH_ORDER_INCLUDE,
} from '../../types/payment.types';

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

  private async findOne(where: Prisma.TransactionWhereInput, errorMessage: string): RepositoryResponse<TransactionWithOrder | null> {
    return repositoryResponse(async () => {
      return this.prisma.transaction.findFirst({
        where,
        include: TRANSACTION_WITH_ORDER_INCLUDE,
      });
    }, errorMessage);
  }
}
