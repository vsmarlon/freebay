import { RepositoryResponse } from '@/shared/core/either';
import { Transaction, Order, Prisma } from '@prisma/client';

export type TransactionWithOrder = Transaction & {
  order: Order & {
    buyer: { id: string; displayName: string };
    seller: { id: string; displayName: string };
  };
};

export abstract class TransactionRepository {
  abstract markAsPaid(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>;
  abstract markAsFailed(id: string, tx?: Prisma.TransactionClient): RepositoryResponse<void>;
  abstract findByIdempotencyKey(key: string): RepositoryResponse<TransactionWithOrder | null>;
}
