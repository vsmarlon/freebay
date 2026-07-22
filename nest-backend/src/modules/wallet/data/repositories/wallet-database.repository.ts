import { Injectable } from '@nestjs/common';
import { PrismaClient, Wallet, Withdrawal, Prisma } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError, DatabaseError } from '@/shared/core/errors';
import { WalletRepository, TransactionEntry } from '../../domain/repositories/wallet.repository';

@Injectable()
export class WalletDatabaseRepository implements WalletRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findByUserId(userId: string): RepositoryResponse<Wallet | null> {
    try {
      return right(await this.prisma.wallet.findUnique({ where: { userId } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar carteira'));
    }
  }

  async getTransactions(userId: string): RepositoryResponse<TransactionEntry[]> {
    try {
      const [ordersAsBuyer, ordersAsSeller] = await Promise.all([
        this.prisma.order.findMany({
          where: { buyerId: userId },
          select: { id: true, amount: true, status: true, createdAt: true, sellerId: true, product: { select: { title: true } } },
        }),
        this.prisma.order.findMany({
          where: { sellerId: userId },
          select: { id: true, amount: true, status: true, createdAt: true, sellerAmount: true, product: { select: { title: true } } },
        }),
      ]);

      const buyerTx: TransactionEntry[] = ordersAsBuyer.map((o) => ({
        id: o.id,
        orderId: o.id,
        amount: o.amount,
        status: o.status,
        createdAt: o.createdAt,
        type: 'PURCHASE' as const,
        productTitle: o.product?.title ?? null,
      }));

      const sellerTx: TransactionEntry[] = ordersAsSeller.map((o) => ({
        id: o.id + '-sale',
        orderId: o.id,
        amount: o.sellerAmount ?? 0,
        status: o.status,
        createdAt: o.createdAt,
        type: 'SALE' as const,
        productTitle: o.product?.title ?? null,
      }));

      const all = [...buyerTx, ...sellerTx].sort(
        (a, b) => b.createdAt.getTime() - a.createdAt.getTime(),
      );

      return right(all);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar transações'));
    }
  }

  async getWithdrawals(walletId: string): RepositoryResponse<Withdrawal[]> {
    try {
      return right(
        await this.prisma.withdrawal.findMany({
          where: { walletId },
          orderBy: { createdAt: 'desc' },
        }),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar saques'));
    }
  }

  async createWithdrawal(data: Prisma.WithdrawalCreateInput): RepositoryResponse<Withdrawal> {
    try {
      return right(await this.prisma.withdrawal.create({ data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar saque'));
    }
  }

  async updateBalance(userId: string, data: Prisma.WalletUpdateInput): RepositoryResponse<Wallet> {
    try {
      return right(await this.prisma.wallet.update({ where: { userId }, data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao atualizar saldo'));
    }
  }

  async updateRecipient(userId: string, recipientId: string): RepositoryResponse<Wallet> {
    try {
      return right(await this.prisma.wallet.update({ where: { userId }, data: { recipientId } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao atualizar recipient'));
    }
  }

  async findUserById(userId: string): RepositoryResponse<{ id: string } | null> {
    try {
      return right(await this.prisma.user.findUnique({ where: { id: userId }, select: { id: true } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar usuário'));
    }
  }

  async creditPending(userId: string, amount: number, tx?: Prisma.TransactionClient): RepositoryResponse<void> {
    try {
      const client = tx ?? this.prisma;
      await client.wallet.upsert({
        where: { userId },
        create: {
          user: { connect: { id: userId } },
          pendingBalance: amount,
        },
        update: { pendingBalance: { increment: amount } },
      });
      return right(undefined);
    } catch {
      return left(new DatabaseError('Failed to credit pending balance'));
    }
  }

  async findWithdrawalByIdempotencyKey(key: string): RepositoryResponse<Withdrawal | null> {
    try {
      return right(await this.prisma.withdrawal.findUnique({ where: { idempotencyKey: key } }));
    } catch {
      return left(new DatabaseError('Failed to find withdrawal by idempotency key'));
    }
  }
}
