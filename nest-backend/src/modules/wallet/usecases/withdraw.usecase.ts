import { Injectable } from '@nestjs/common';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, InsufficientBalanceError, BadRequestError, DatabaseError } from '@/shared/core/errors';
import { WalletRepository } from '../domain/repositories/wallet.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { WithdrawInput } from '../dtos/wallet.dto';
import { Wallet, Withdrawal } from '@prisma/client';

@Injectable()
export class WithdrawUseCase {
  constructor(
    private walletRepository: WalletRepository,
    private prisma: PrismaService,
  ) {}

  async execute(input: WithdrawInput): RepositoryResponse<Withdrawal> {
    try {
      if (input.idempotencyKey) {
        const existing = await this.walletRepository.findWithdrawalByIdempotencyKey(input.idempotencyKey);
        if (existing.isRight() && existing.value) {
          return right(existing.value);
        }
      }

      const withdrawal = await this.prisma.$transaction(async (tx) => {
        if (input.idempotencyKey) {
          const existing = await tx.withdrawal.findUnique({
            where: { idempotencyKey: input.idempotencyKey },
          });
          if (existing) {
            return existing;
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

        const created = await tx.withdrawal.create({
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

        return created;
      });

      return right(withdrawal);
    } catch (error: any) {
      const isP2002 = error && (error.code === 'P2002' || (error.message && typeof error.message === 'string' && error.message.includes('P2002')));
      if (input.idempotencyKey && isP2002) {
        const existing = await this.walletRepository.findWithdrawalByIdempotencyKey(input.idempotencyKey);
        if (existing.isRight() && existing.value) {
          return right(existing.value);
        }
      }
      if (error instanceof AppError) {
        return left(error);
      }
      return left(new DatabaseError(error instanceof Error ? error.message : 'Erro interno ao realizar saque'));
    }
  }
}
