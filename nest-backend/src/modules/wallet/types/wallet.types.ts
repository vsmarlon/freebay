import { WalletBalanceKind, WalletEntryReason } from '@prisma/client';

export type TransactionEntry = {
  id: string;
  orderId: string | null;
  amount: number;
  kind: WalletBalanceKind;
  reason: WalletEntryReason;
  createdAt: Date;
  productTitle: string | null;
};
