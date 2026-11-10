import {
  Prisma,
  ReversalState,
  TransactionStatus,
  TransferDeliveryState,
} from '@prisma/client';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse } from '@/shared/core/either';

export class TransactionGuardedClaimsRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  private updateCount(
    where: Prisma.TransactionWhereInput,
    data: Prisma.TransactionUpdateManyMutationInput,
    tx?: Prisma.TransactionClient,
  ): Promise<{ count: number }> {
    const client = tx ?? this.prisma;
    return client.transaction.updateMany({ where, data }).then((result) => ({ count: result.count }));
  }

  async markAsPaid(id: string, chargeId: string | null, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => this.updateCount(
      { id, status: TransactionStatus.PENDING },
      { status: TransactionStatus.PAID, paidAt: new Date(), ...(chargeId ? { chargeId } : {}) },
      tx,
    ), 'Failed to mark transaction as paid');
  }

  async setChargeId(orderId: string, chargeId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.updateCount({ orderId, chargeId: null }, { chargeId }, tx);
    }, 'Failed to persist charge id');
  }

  async claimTransfer(orderId: string, processingAt: Date, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => this.updateCount(
      { orderId, transferState: { in: [TransferDeliveryState.PENDING, TransferDeliveryState.RETRYABLE] } },
      { transferState: TransferDeliveryState.PROCESSING, transferProcessingAt: processingAt, transferAttempts: { increment: 1 } },
      tx,
    ), 'Failed to claim transfer');
  }

  async reclaimStaleTransfer(cutoff: Date, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => this.updateCount(
      { transferState: TransferDeliveryState.PROCESSING, transferProcessingAt: { lt: cutoff } },
      { transferState: TransferDeliveryState.RETRYABLE, transferLastError: 'Processing lease expired' },
      tx,
    ), 'Failed to reclaim stale transfers');
  }

  async finalizeTransfer(id: string, transferId: string, tx: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => this.updateCount(
      { id, transferState: TransferDeliveryState.PROCESSING, transferId: null },
      { transferId, transferState: TransferDeliveryState.SUCCEEDED, reversalState: ReversalState.PENDING, transferProcessingAt: null, transferLastError: null, releasedAt: new Date() },
      tx,
    ), 'Failed to finalize transfer');
  }

  async markTransferFailure(
    id: string,
    state: Extract<TransferDeliveryState, 'RETRYABLE' | 'TERMINAL'>,
    error: string,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => this.updateCount(
      { id, transferState: TransferDeliveryState.PROCESSING },
      { transferState: state, transferProcessingAt: null, transferLastError: error },
      tx,
    ), 'Failed to persist transfer failure');
  }

  async claimReversal(orderId: string, processingAt: Date, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => this.updateCount(
      { orderId, transferId: { not: null }, reversalState: { in: [ReversalState.PENDING, ReversalState.RETRYABLE] } },
      { reversalState: ReversalState.PROCESSING, reversalProcessingAt: processingAt, reversalAttempts: { increment: 1 } },
      tx,
    ), 'Failed to claim reversal');
  }

  async finalizeReversal(id: string, reversalId: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => this.updateCount(
      { id, reversalState: ReversalState.PROCESSING, reversalId: null },
      { reversalId, reversalState: ReversalState.SUCCEEDED, reversalProcessingAt: null, reversalLastError: null },
      tx,
    ), 'Failed to finalize reversal');
  }

  async markReversalFailure(id: string, state: Extract<ReversalState, 'RETRYABLE' | 'TERMINAL'>, error: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => this.updateCount(
      { id, reversalState: ReversalState.PROCESSING },
      { reversalState: state, reversalProcessingAt: null, reversalLastError: error },
      tx,
    ), 'Failed to persist reversal failure');
  }

  async reclaimStaleReversal(cutoff: Date, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> {
    return repositoryResponse(async () => {
      const result = await (tx ?? this.prisma).transaction.updateMany({
        where: { reversalState: ReversalState.PROCESSING, reversalProcessingAt: { lt: cutoff } },
        data: { reversalState: ReversalState.RETRYABLE, reversalLastError: 'Processing lease expired' },
      });
      return { count: result.count };
    }, 'Failed to reclaim stale reversals');
  }
}
