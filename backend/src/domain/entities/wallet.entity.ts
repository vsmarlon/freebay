export interface WalletEntity {
  id: string;
  userId: string;
  availableBalance: number;
  pendingBalance: number;
  totalEarned: number;
  recipientId: string | null;
}

export interface WithdrawalEntity {
  id: string;
  walletId: string;
  amount: number;
  status: string;
  createdAt: Date;
}
