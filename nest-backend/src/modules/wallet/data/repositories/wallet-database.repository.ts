import { Injectable } from '@nestjs/common';
import { Wallet, Prisma, WalletBalanceKind, WalletEntryReason } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { buildIdCursorPage, CursorPage, PageQuery, mapPage } from '@/shared/core/pagination';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { TransactionEntry } from '../../types/wallet.types';
import { WalletRepository } from '../../domain/repositories/wallet.repository';

const WALLET_ENTRY_INCLUDE = {
  order: { select: { product: { select: { title: true } } } },
} satisfies Prisma.WalletEntryInclude;

@Injectable()
export class WalletDatabaseRepository implements WalletRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findByUserId(userId: string): RepositoryResponse<Wallet | null> {
    return repositoryResponse(() => this.prisma.wallet.findUnique({ where: { userId } }), 'Erro ao buscar carteira');
  }

  async ensureForUser(userId: string, tx?: Prisma.TransactionClient): RepositoryResponse<Wallet> {
    return repositoryResponse(
      () => (tx ?? this.prisma).wallet.upsert({
        where: { userId },
        create: { userId, availableBalance: 0, pendingBalance: 0, totalEarned: 0 },
        update: {},
      }),
      'Erro ao garantir carteira',
    );
  }

  async getTransactions(
    userId: string,
    page: PageQuery,
  ): RepositoryResponse<CursorPage<TransactionEntry>> {
    return repositoryResponse(async () => {
      const rows = await this.prisma.walletEntry.findMany({
        where: { userId, kind: { not: WalletBalanceKind.TOTAL_EARNED } },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: page.limit + 1,
        ...(page.cursor ? { cursor: { id: page.cursor }, skip: 1 } : {}),
        include: WALLET_ENTRY_INCLUDE,
      });
      const entries = buildIdCursorPage(rows, page.limit);

      return mapPage(entries, (entry) => ({
        id: entry.id,
        orderId: entry.orderId,
        amount: entry.amount,
        kind: entry.kind,
        reason: entry.reason,
        createdAt: entry.createdAt,
        productTitle: entry.order?.product?.title ?? null,
      }));
    }, 'Erro ao buscar transações');
  }

  async findUserById(userId: string): RepositoryResponse<{ id: string } | null> {
    return repositoryResponse(() => this.prisma.user.findUnique({ where: { id: userId }, select: { id: true } }), 'Erro ao buscar usuário');
  }

  async creditPending(
    userId: string,
    amount: number,
    orderId: string,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<void> {
    return repositoryResponse(
      () =>
        applyWalletDelta(
          tx ?? this.prisma,
          userId,
          { pendingBalance: amount },
          { reason: WalletEntryReason.SALE_HELD, orderId },
        ),
      'Failed to credit pending balance',
    );
  }

}
