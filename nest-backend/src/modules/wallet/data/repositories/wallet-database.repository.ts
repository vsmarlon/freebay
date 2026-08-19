import { Injectable } from '@nestjs/common';
import { Wallet, Withdrawal, Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { WalletRepository } from '../../domain/repositories/wallet.repository';
import { TransactionEntry } from '../../types/wallet.types';

@Injectable()
export class WalletDatabaseRepository extends BasePrismaRepository implements WalletRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findByUserId(userId: string): RepositoryResponse<Wallet | null> {
    return this.safeRun(() => this.prisma.wallet.findUnique({ where: { userId } }), 'Erro ao buscar carteira');
  }

  async getTransactions(userId: string): RepositoryResponse<TransactionEntry[]> {
    return this.safeRun(async () => {
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

      return [...buyerTx, ...sellerTx].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    }, 'Erro ao buscar transações');
  }

  async getWithdrawals(walletId: string): RepositoryResponse<Withdrawal[]> {
    return this.safeRun(() => this.prisma.withdrawal.findMany({
      where: { walletId },
      orderBy: { createdAt: 'desc' },
    }), 'Erro ao buscar saques');
  }

  async createWithdrawal(data: Prisma.WithdrawalCreateInput): RepositoryResponse<Withdrawal> {
    return this.safeRun(() => this.prisma.withdrawal.create({ data }), 'Erro ao criar saque');
  }

  async updateBalance(userId: string, data: Prisma.WalletUpdateInput): RepositoryResponse<Wallet> {
    return this.safeRun(() => this.prisma.wallet.update({ where: { userId }, data }), 'Erro ao atualizar saldo');
  }

  async updateRecipient(userId: string, recipientId: string): RepositoryResponse<Wallet> {
    return this.safeRun(() => this.prisma.wallet.update({ where: { userId }, data: { recipientId } }), 'Erro ao atualizar recipient');
  }

  async findUserById(userId: string): RepositoryResponse<{ id: string } | null> {
    return this.safeRun(() => this.prisma.user.findUnique({ where: { id: userId }, select: { id: true } }), 'Erro ao buscar usuário');
  }

  async creditPending(userId: string, amount: number, tx?: Prisma.TransactionClient): RepositoryResponse<void> {
    return this.safeRun(async () => {
      const client = tx ?? this.prisma;
      await client.wallet.upsert({
        where: { userId },
        create: { user: { connect: { id: userId } }, pendingBalance: amount },
        update: { pendingBalance: { increment: amount } },
      });
    }, 'Failed to credit pending balance');
  }

  async findWithdrawalByIdempotencyKey(key: string): RepositoryResponse<Withdrawal | null> {
    return this.safeRun(() => this.prisma.withdrawal.findUnique({ where: { idempotencyKey: key } }), 'Failed to find withdrawal by idempotency key');
  }
}
