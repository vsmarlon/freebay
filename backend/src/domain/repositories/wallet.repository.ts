import { WalletEntity } from '../entities';

export interface IWalletRepository {
  findByUserId(userId: string): Promise<WalletEntity | null>;
  create(userId: string): Promise<WalletEntity>;
  updateBalance(
    userId: string,
    data: Partial<Pick<WalletEntity, 'availableBalance' | 'pendingBalance' | 'totalEarned'>>,
  ): Promise<WalletEntity>;
  setRecipientId(userId: string, recipientId: string): Promise<WalletEntity>;
}
