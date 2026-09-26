import { Injectable } from '@nestjs/common';
import { Prisma, ReversalState, TransferDeliveryState } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, DEFAULT_PAGE_SIZE } from '@/shared/core/pagination';
import { ExpiredPendingTransaction, TransactionWithOrder, UpsertTransactionData } from '../../types/payment.types';
import { TransactionGuardedClaimsRepository } from './transaction-guarded-claims.repository';
import { TransactionReconciliationRepository } from './transaction-reconciliation.repository';
import { TransactionUpsertRepository } from './transaction-upsert.repository';

@Injectable()
export class TransactionDatabaseRepository {
  private readonly claims: TransactionGuardedClaimsRepository;
  private readonly reconciliation: TransactionReconciliationRepository;
  private readonly upsert: TransactionUpsertRepository;

  constructor(private readonly prisma: PrismaService) {
    this.claims = new TransactionGuardedClaimsRepository(prisma);
    this.reconciliation = new TransactionReconciliationRepository(prisma);
    this.upsert = new TransactionUpsertRepository(prisma);
  }

  markAsPaid(id: string, chargeId: string | null, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> { return this.claims.markAsPaid(id, chargeId, tx); }
  setChargeId(orderId: string, chargeId: string, tx?: Prisma.TransactionClient): RepositoryResponse<void> { return this.claims.setChargeId(orderId, chargeId, tx); }
  claimTransfer(orderId: string, processingAt: Date, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> { return this.claims.claimTransfer(orderId, processingAt, tx); }
  reclaimStaleTransfer(cutoff: Date, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> { return this.claims.reclaimStaleTransfer(cutoff, tx); }
  finalizeTransfer(id: string, transferId: string, tx: Prisma.TransactionClient): RepositoryResponse<{ count: number }> { return this.claims.finalizeTransfer(id, transferId, tx); }
  markTransferFailure(id: string, state: Extract<TransferDeliveryState, 'RETRYABLE' | 'TERMINAL'>, error: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> { return this.claims.markTransferFailure(id, state, error, tx); }
  claimReversal(orderId: string, processingAt: Date, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> { return this.claims.claimReversal(orderId, processingAt, tx); }
  finalizeReversal(id: string, reversalId: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> { return this.claims.finalizeReversal(id, reversalId, tx); }
  markReversalFailure(id: string, state: Extract<ReversalState, 'RETRYABLE' | 'TERMINAL'>, error: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> { return this.claims.markReversalFailure(id, state, error, tx); }
  reclaimStaleReversal(cutoff: Date, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }> { return this.claims.reclaimStaleReversal(cutoff, tx); }

  findTransferFailures(cursor: { updatedAt: Date; id: string } | null = null, limit = DEFAULT_PAGE_SIZE): RepositoryResponse<CursorPage<TransactionWithOrder>> { return this.reconciliation.findTransferFailures(cursor, limit); }
  markAsFailed(id: string, tx?: Prisma.TransactionClient) { return this.reconciliation.markAsFailed(id, tx); }
  findByIdempotencyKey(key: string) { return this.reconciliation.findByIdempotencyKey(key); }
  findByChargeId(chargeId: string) { return this.reconciliation.findByChargeId(chargeId); }
  findByOrderId(orderId: string) { return this.reconciliation.findByOrderId(orderId); }

  findExpiredPending(now: Date): RepositoryResponse<ExpiredPendingTransaction[]> { return this.upsert.findExpiredPending(now); }
  upsertTransaction(data: UpsertTransactionData) { return this.upsert.upsertTransaction(data); }
}
