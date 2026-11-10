import { Prisma, Wallet } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';

export abstract class WalletRepository {
  abstract ensureForUser(userId: string, tx?: Prisma.TransactionClient): RepositoryResponse<Wallet>;
  abstract findByUserId(userId: string): RepositoryResponse<Wallet | null>;
}
