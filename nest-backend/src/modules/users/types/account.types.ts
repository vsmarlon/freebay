export interface AccountDeletionBlockers {
  openOrdersAsBuyer: number;
  openOrdersAsSeller: number;
  openDisputes: number;
  walletBalance: number;
}

export interface AccountDeletionState {
  deletionRequestedAt: Date | null;
  purgeAfter: Date | null;
}

export interface PurgeCandidate {
  id: string;
  avatarUrl: string | null;
  bannerUrl: string | null;
}

export type UserDataExport = Record<string, unknown>;
