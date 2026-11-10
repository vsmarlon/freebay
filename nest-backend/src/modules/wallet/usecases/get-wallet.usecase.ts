import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { WalletRepository } from '../domain/repositories/wallet.repository';
import { GetWalletOutput } from '../dtos/wallet.dto';

@Injectable()
export class GetWalletUseCase {
  constructor(private walletRepository: WalletRepository) {}

  async execute(userId: string): Promise<Either<AppError, GetWalletOutput>> {
    const result = await this.walletRepository.ensureForUser(userId);
    if (result.isLeft()) return left(result.value);
    const wallet = result.value;
    return right({
      balance: wallet.availableBalance + wallet.pendingBalance,
      pendingBalance: wallet.pendingBalance,
      availableBalance: wallet.availableBalance,
    });
  }
}
