import { RepositoryResponse } from '@/shared/core/either';
import { Transaction, Prisma } from '@prisma/client';
import {
  ExpiredPendingTransaction,
  TransactionWithOrder,
  UpsertTransactionData,
} from '../../types/payment.types';

export abstract class TransactionRepository {
  abstract markAsPaid(
    id: string,
    chargeId: string | null,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<{ count: number }>;
  abstract setChargeId(
    orderId: string,
    chargeId: string,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<void>;
  abstract claimTransfer(
    orderId: string,
    transferId: string,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<{ count: number }>;
  abstract markAsFailed(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }>;
  abstract findByIdempotencyKey(key: string): RepositoryResponse<TransactionWithOrder | null>;
  abstract findByOrderId(orderId: string): RepositoryResponse<TransactionWithOrder | null>;
  abstract findByChargeId(chargeId: string): RepositoryResponse<TransactionWithOrder | null>;
  abstract findByDerivedKey(key: string): RepositoryResponse<Transaction | null>;
  abstract findExpiredPending(now: Date): RepositoryResponse<ExpiredPendingTransaction[]>;
  abstract upsertTransaction(data: UpsertTransactionData): RepositoryResponse<void>;
}
