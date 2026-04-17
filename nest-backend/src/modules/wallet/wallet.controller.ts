import { Controller, Get, Post, Body, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { GetWalletUseCase, WithdrawUseCase, RegisterBankAccountUseCase } from './usecases/wallet.usecase';
import { WithdrawDTO, withdrawSchema } from './dtos/wallet.dto';
import { PrismaWalletRepository } from './repositories/wallet.repository';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { ZodValidationPipe } from '@/shared/pipes/zod-validation.pipe';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { z } from 'zod';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

const bankAccountSchema = z.object({
  bankCode: z.string().min(3),
  accountNumber: z.string().min(1),
  accountCheckDigit: z.string().min(1),
  branchNumber: z.string().min(1),
  branchCheckDigit: z.string().min(1),
  holderName: z.string().min(1),
  holderDocument: z.string().min(11).max(14),
});

@Controller('wallet')
@UseGuards(JwtAuthGuard)
export class WalletController {
  constructor(
    private readonly getWalletUseCase: GetWalletUseCase,
    private readonly withdrawUseCase: WithdrawUseCase,
    private readonly registerBankAccountUseCase: RegisterBankAccountUseCase,
    private readonly walletRepository: PrismaWalletRepository,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  async getWallet(@CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const result = await this.getWalletUseCase.execute(userId);
    return result;
  }

  @Post('withdraw')
  @HttpCode(HttpStatus.CREATED)
  async withdraw(@CurrentUser() user: AuthUser, @Body(new ZodValidationPipe(withdrawSchema)) body: WithdrawDTO) {
    const userId = user.userId;
    const result = await this.withdrawUseCase.execute({ userId, ...body });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('bank-account')
  @HttpCode(HttpStatus.CREATED)
  async registerBankAccount(@CurrentUser() user: AuthUser, @Body(new ZodValidationPipe(bankAccountSchema)) body: z.infer<typeof bankAccountSchema>) {
    const userId = user.userId;
    const result = await this.registerBankAccountUseCase.execute({ userId, ...body });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get('transactions')
  async getTransactions(@CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const transactions = await this.walletRepository.getTransactions(userId);
    return { transactions };
  }

  @Get('withdrawals')
  async getWithdrawals(@CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const wallet = await this.walletRepository.findByUserId(userId);
    if (!wallet) {
      return { withdrawals: [] };
    }

    const withdrawals = await this.prisma.withdrawal.findMany({
      where: { walletId: wallet.id },
      orderBy: { createdAt: 'desc' },
    });
    return { withdrawals };
  }
}
