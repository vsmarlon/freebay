import { Prisma, WalletBalanceKind, WalletEntryReason } from '@prisma/client';

export interface WalletDelta {
  availableBalance?: number;
  pendingBalance?: number;
  totalEarned?: number;
}

export interface WalletMutationContext {
  reason: WalletEntryReason;
  orderId?: string;
  transferId?: string;
}

export class WalletMissingError extends Error {
  constructor(userId: string) {
    super(`Carteira inexistente para o usuário ${userId}; débito recusado`);
    this.name = 'WalletMissingError';
  }
}

const BALANCE_FIELDS = ['availableBalance', 'pendingBalance', 'totalEarned'] as const;

const ENTRY_KIND: Record<(typeof BALANCE_FIELDS)[number], WalletBalanceKind> = {
  availableBalance: WalletBalanceKind.AVAILABLE,
  pendingBalance: WalletBalanceKind.PENDING,
  totalEarned: WalletBalanceKind.TOTAL_EARNED,
};

export async function applyWalletDelta(
  tx: Prisma.TransactionClient,
  userId: string,
  delta: WalletDelta,
  context: WalletMutationContext,
): Promise<void> {
  const applied = BALANCE_FIELDS.filter((field) => (delta[field] ?? 0) !== 0);
  if (applied.length === 0) return;

  if (applied.some((field) => (delta[field] as number) < 0)) {
    const existing = await tx.wallet.findUnique({ where: { userId } });
    if (!existing) {
      throw new WalletMissingError(userId);
    }
  }

  await tx.wallet.upsert({
    where: { userId },
    create: {
      user: { connect: { id: userId } },
      ...Object.fromEntries(applied.map((field) => [field, delta[field] as number])),
    },
    update: Object.fromEntries(
      applied.map((field) => [field, { increment: delta[field] as number }]),
    ),
  });

  await tx.walletEntry.createMany({
    data: applied.map((field) => ({
      userId,
      kind: ENTRY_KIND[field],
      amount: delta[field] as number,
      reason: context.reason,
      orderId: context.orderId ?? null,
      transferId: context.transferId ?? null,
    })),
  });
}
