import { IWalletRepository } from '@/domain/repositories';
import { WalletEntity } from '@/domain/entities';
import { Either, left, right } from '@/domain/either';
import {
  AppError,
  NotFoundError,
  InsufficientBalanceError,
  NoRecipientError,
} from '@/domain/errors';

export class GetWalletUseCase {
  constructor(private walletRepository: IWalletRepository) {}

  async execute(userId: string): Promise<Either<AppError, WalletEntity>> {
    const wallet = await this.walletRepository.findByUserId(userId);
    if (!wallet) {
      // Auto-create wallet for user on first access
      const newWallet = await this.walletRepository.create(userId);
      return right(newWallet);
    }
    return right(wallet);
  }
}

export class WithdrawUseCase {
  constructor(private walletRepository: IWalletRepository) {}

  async execute(userId: string, amount: number): Promise<Either<AppError, WalletEntity>> {
    const wallet = await this.walletRepository.findByUserId(userId);
    if (!wallet) {
      return left(new NotFoundError('Carteira'));
    }
    if (wallet.availableBalance < amount) {
      return left(new InsufficientBalanceError());
    }
    if (!wallet.recipientId) {
      return left(new NoRecipientError());
    }

    const updated = await this.walletRepository.updateBalance(userId, {
      availableBalance: wallet.availableBalance - amount,
    });

    // TODO: Call Pagar.me Recipients API to transfer to seller's bank account

    return right(updated);
  }
}
