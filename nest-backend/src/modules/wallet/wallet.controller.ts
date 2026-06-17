import { Controller, Get, Post, Body, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { GetWalletUseCase, WithdrawUseCase, RegisterBankAccountUseCase } from './usecases/wallet.usecase';
import { WithdrawDTO, BankAccountDTO, WalletResponse } from './dtos/wallet.dto';
import { PrismaWalletRepository } from './repositories/wallet.repository';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

@ApiTags('Wallet')
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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get wallet',
    description: 'Returns current wallet balance, pending balance, and available balance',
    auth: true,
    responseType: WalletResponse,
  })
  async getWallet(@CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const result = await this.getWalletUseCase.execute(userId);
    return result;
  }

  @Post('withdraw')
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Request withdrawal',
    description: 'Request a PIX withdrawal from the wallet',
    auth: true,
    bodyType: WithdrawDTO,
    responseStatus: 201,
    errors: [{ status: 400, description: 'Insufficient balance or invalid data' }],
  })
  async withdraw(@CurrentUser() user: AuthUser, @Body() body: WithdrawDTO) {
    const userId = user.userId;
    const result = await this.withdrawUseCase.execute({ userId, ...body });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('bank-account')
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Register bank account',
    description: 'Register a bank account for withdrawals',
    auth: true,
    bodyType: BankAccountDTO,
    responseStatus: 201,
  })
  async registerBankAccount(@CurrentUser() user: AuthUser, @Body() body: BankAccountDTO) {
    const userId = user.userId;
    const result = await this.registerBankAccountUseCase.execute({ userId, ...body });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get('transactions')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get transactions',
    description: 'Returns the transaction history for the wallet',
    auth: true,
  })
  async getTransactions(@CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const transactions = await this.walletRepository.getTransactions(userId);
    return { transactions };
  }

  @Get('withdrawals')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get withdrawals',
    description: 'Returns the withdrawal history for the wallet',
    auth: true,
  })
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
