import { Injectable } from '@nestjs/common';
import { Wallet, Prisma, WalletBalanceKind, WalletEntryReason } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage, PageQuery, mapPage, paginateById } from '@/shared/core/pagination';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { TransactionEntry } from '../../types/wallet.types';
import { WalletRepository } from '../../domain/repositories/wallet.repository';

const WALLET_ENTRY_INCLUDE = {
  order: { select: { product: { select: { title: true } } } },
} satisfies Prisma.WalletEntryInclude;

@Injectable()
export class WalletDatabaseRepository extends BasePrismaRepository implements WalletRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findByUserId(userId: string): RepositoryResponse<Wallet | null> {
    return this.safeRun(() => this.prisma.wallet.findUnique({ where: { userId } }), 'Erro ao buscar carteira');
  }

  async ensureForUser(userId: string, tx?: Prisma.TransactionClient): RepositoryResponse<Wallet> {
    return this.safeRun(
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
    return this.safeRun(async () => {
      const entries = await paginateById<
        Prisma.WalletEntryGetPayload<{ include: typeof WALLET_ENTRY_INCLUDE }>,
        Prisma.WalletEntryFindManyArgs
      >(
        (args) =>
          this.prisma.walletEntry.findMany(args) as Promise<
            Prisma.WalletEntryGetPayload<{ include: typeof WALLET_ENTRY_INCLUDE }>[]
          >,
        {
          where: { userId, kind: { not: WalletBalanceKind.TOTAL_EARNED } },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
          include: WALLET_ENTRY_INCLUDE,
        },
        page,
      );

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
    return this.safeRun(() => this.prisma.user.findUnique({ where: { id: userId }, select: { id: true } }), 'Erro ao buscar usuário');
  }

  async creditPending(
    userId: string,
    amount: number,
    orderId: string,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<void> {
    return this.safeRun(
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
