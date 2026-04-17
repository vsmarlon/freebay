import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, InsufficientBalanceError, BadRequestError } from '@/shared/core/errors';
import { PrismaWalletRepository } from '../repositories/wallet.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { GetWalletOutput, WithdrawInput } from '../dtos/wallet.dto';
import { v4 as uuidv4 } from 'uuid';

export type { GetWalletOutput, WithdrawInput };

@Injectable()
export class GetWalletUseCase {
  constructor(private walletRepository: PrismaWalletRepository) {}

  async execute(userId: string): Promise<GetWalletOutput> {
    const wallet = await this.walletRepository.findByUserId(userId);
    if (!wallet) {
      return { balance: 0, pendingBalance: 0, availableBalance: 0 };
    }

    return {
      balance: wallet.availableBalance + wallet.pendingBalance,
      pendingBalance: wallet.pendingBalance,
      availableBalance: wallet.availableBalance,
    };
  }
}

@Injectable()
export class WithdrawUseCase {
  constructor(
    private walletRepository: PrismaWalletRepository,
    private prisma: PrismaService,
  ) {}

  async execute(input: WithdrawInput): Promise<Either<AppError, { withdrawalId: string; status: string }>> {
    const wallet = await this.walletRepository.findByUserId(input.userId);

    if (!wallet) {
      return left(new NotFoundError('Wallet'));
    }

    if (wallet.availableBalance < input.amount) {
      return left(new InsufficientBalanceError());
    }

    const MIN_WITHDRAWAL = 2000;
    if (input.amount < MIN_WITHDRAWAL) {
      return left(new BadRequestError(`Minimum withdrawal is R$ ${MIN_WITHDRAWAL / 100}`));
    }

    const withdrawal = await this.prisma.withdrawal.create({
      data: {
        walletId: wallet.id,
        amount: input.amount,
        status: 'PENDING',
      },
    });

    await this.prisma.wallet.update({
      where: { userId: input.userId },
      data: { availableBalance: { decrement: input.amount } },
    });

    return right({ withdrawalId: withdrawal.id, status: withdrawal.status });
  }
}

@Injectable()
export class RegisterBankAccountUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: {
    userId: string;
    bankCode: string;
    accountNumber: string;
    accountCheckDigit: string;
    branchNumber: string;
    branchCheckDigit: string;
    holderName: string;
    holderDocument: string;
  }): Promise<Either<AppError, { registered: boolean }>> {
    const user = await this.prisma.user.findUnique({ where: { id: input.userId } });
    if (!user) {
      return left(new NotFoundError('User'));
    }

    const wallet = await this.prisma.wallet.findUnique({ where: { userId: input.userId } });
    if (!wallet) {
      return left(new NotFoundError('Wallet'));
    }

    const recipientId = `rec_${uuidv4().replace(/-/g, '').substring(0, 16)}`;

    await this.prisma.wallet.update({
      where: { userId: input.userId },
      data: { recipientId },
    });

    return right({ registered: true });
  }
}
