import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, DatabaseError } from '@/shared/core/errors';
import { PrismaWalletRepository } from '../repositories/wallet.repository';
import { GetWalletOutput } from '../dtos/wallet.dto';

@Injectable()
export class GetWalletUseCase {
  constructor(private walletRepository: PrismaWalletRepository) {}

  async execute(userId: string): Promise<Either<AppError, GetWalletOutput>> {
    try {
      const wallet = await this.walletRepository.findByUserId(userId);
      if (!wallet) return right({ balance: 0, pendingBalance: 0, availableBalance: 0 });
      return right({
        balance: wallet.availableBalance + wallet.pendingBalance,
        pendingBalance: wallet.pendingBalance,
        availableBalance: wallet.availableBalance,
      });
    } catch {
      return left(new DatabaseError());
    }
  }
}
