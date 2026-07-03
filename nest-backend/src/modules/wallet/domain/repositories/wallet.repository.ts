import { RepositoryResponse } from '@/shared/core/either';
import { Wallet, Withdrawal, Prisma } from '@prisma/client';

export type TransactionEntry = {
  id: string;
  orderId: string;
  amount: number;
  status: string;
  createdAt: Date;
  type: 'PURCHASE' | 'SALE';
};

export abstract class WalletRepository {
  abstract findByUserId(userId: string): RepositoryResponse<Wallet | null>;
  abstract getTransactions(userId: string): RepositoryResponse<TransactionEntry[]>;
  abstract getWithdrawals(walletId: string): RepositoryResponse<Withdrawal[]>;
  abstract createWithdrawal(data: Prisma.WithdrawalCreateInput): RepositoryResponse<Withdrawal>;
  abstract updateBalance(userId: string, data: Prisma.WalletUpdateInput): RepositoryResponse<Wallet>;
  abstract updateRecipient(userId: string, recipientId: string): RepositoryResponse<Wallet>;
  abstract findUserById(userId: string): RepositoryResponse<{ id: string } | null>;
}
