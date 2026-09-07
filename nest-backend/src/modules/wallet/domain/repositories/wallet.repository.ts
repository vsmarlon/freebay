import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, PageQuery } from '@/shared/core/pagination';
import { Wallet, Prisma } from '@prisma/client';
import { TransactionEntry } from '../../types/wallet.types';

export abstract class WalletRepository {
  abstract findByUserId(userId: string): RepositoryResponse<Wallet | null>;
  abstract getTransactions(
    userId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<TransactionEntry>>;
  abstract findUserById(userId: string): RepositoryResponse<{ id: string } | null>;
  abstract creditPending(
    userId: string,
    amount: number,
    orderId: string,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<void>;
}
