import { RepositoryResponse } from '@/shared/core/either';
import { Transaction, Prisma } from '@prisma/client';
import { TransactionWithOrder, UpsertTransactionData } from '../../types/payment.types';

export abstract class TransactionRepository {
  abstract markAsPaid(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }>;
  abstract markAsFailed(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<{ count: number }>;
  abstract findByIdempotencyKey(key: string): RepositoryResponse<TransactionWithOrder | null>;
  abstract findByOrderId(orderId: string): RepositoryResponse<TransactionWithOrder | null>;
  abstract findByDerivedKey(key: string): RepositoryResponse<Transaction | null>;
  abstract upsertTransaction(data: UpsertTransactionData): RepositoryResponse<void>;
}
