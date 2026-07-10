import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, InsufficientBalanceError, BadRequestError, DatabaseError } from '@/shared/core/errors';
import { PrismaWalletRepository } from '../repositories/wallet.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { GetWalletOutput, WithdrawInput } from '../dtos/wallet.dto';
import { v4 as uuidv4 } from 'uuid';
import { Wallet } from '@prisma/client';

export type { GetWalletOutput, WithdrawInput };

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

@Injectable()
export class WithdrawUseCase {
  constructor(
    private walletRepository: PrismaWalletRepository,
    private prisma: PrismaService,
  ) {}

  async execute(input: WithdrawInput): Promise<Either<AppError, { withdrawalId: string; status: string }>> {
    try {
      if (input.idempotencyKey) {
        const existing = await this.prisma.withdrawal.findUnique({
          where: { idempotencyKey: input.idempotencyKey },
        });
        if (existing) {
          return right({ withdrawalId: existing.id, status: existing.status });
        }
      }

      const result = await this.prisma.$transaction(async (tx) => {
        if (input.idempotencyKey) {
          const existing = await tx.withdrawal.findUnique({
            where: { idempotencyKey: input.idempotencyKey },
          });
          if (existing) {
            return { withdrawalId: existing.id, status: existing.status };
          }
        }

        const wallets = await tx.$queryRaw<Wallet[]>`
          SELECT * FROM "Wallet" WHERE "userId" = ${input.userId} FOR UPDATE
        `;
        const wallet = wallets[0];

        if (!wallet) {
          throw new NotFoundError('Wallet');
        }

        if (wallet.availableBalance < input.amount) {
          throw new InsufficientBalanceError();
        }

        const MIN_WITHDRAWAL = 2000;
        if (input.amount < MIN_WITHDRAWAL) {
          throw new BadRequestError(`Minimum withdrawal is R$ ${MIN_WITHDRAWAL / 100}`);
        }

        const withdrawal = await tx.withdrawal.create({
          data: {
            walletId: wallet.id,
            amount: input.amount,
            status: 'PENDING',
            idempotencyKey: input.idempotencyKey || null,
          },
        });

        await tx.wallet.update({
          where: { userId: input.userId },
          data: { availableBalance: { decrement: input.amount } },
        });

        return { withdrawalId: withdrawal.id, status: withdrawal.status };
      });

      return right(result);
    } catch (error: any) {
      const isP2002 = error && (error.code === 'P2002' || (error.message && typeof error.message === 'string' && error.message.includes('P2002')));
      if (input.idempotencyKey && isP2002) {
        const existing = await this.prisma.withdrawal.findUnique({
          where: { idempotencyKey: input.idempotencyKey },
        });
        if (existing) {
          return right({ withdrawalId: existing.id, status: existing.status });
        }
      }
      if (error instanceof AppError) {
        return left(error);
      }
      return left(new AppError('INTERNAL_ERROR', error instanceof Error ? error.message : 'Erro interno ao realizar saque'));
    }
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
