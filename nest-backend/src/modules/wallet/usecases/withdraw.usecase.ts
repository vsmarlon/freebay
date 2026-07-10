import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, InsufficientBalanceError, BadRequestError } from '@/shared/core/errors';
import { PrismaWalletRepository } from '../repositories/wallet.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { WithdrawInput } from '../dtos/wallet.dto';
import { Wallet } from '@prisma/client';

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
