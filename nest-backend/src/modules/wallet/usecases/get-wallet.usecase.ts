import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { WalletDatabaseRepository } from '../data/repositories/wallet-database.repository';
import { GetWalletOutput } from '../dtos/wallet.dto';

@Injectable()
export class GetWalletUseCase {
  constructor(private walletRepository: WalletDatabaseRepository) {}

  async execute(userId: string): Promise<Either<AppError, GetWalletOutput>> {
    const result = await this.walletRepository.findByUserId(userId);
    if (result.isLeft()) return left(result.value);
    const wallet = result.value;
    if (!wallet) return right({ balance: 0, pendingBalance: 0, availableBalance: 0 });
    return right({
      balance: wallet.availableBalance + wallet.pendingBalance,
      pendingBalance: wallet.pendingBalance,
      availableBalance: wallet.availableBalance,
    });
  }
}
