import { Controller, Get, Post, Body, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { GetWalletUseCase } from './usecases/get-wallet.usecase';
import { WithdrawUseCase } from './usecases/withdraw.usecase';
import { RegisterBankAccountUseCase } from './usecases/register-bank-account.usecase';
import { WithdrawDTO, BankAccountDTO, WalletResponse } from './dtos/wallet.dto';
import { WalletRepository } from './domain/repositories/wallet.repository';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { left, isLeft } from '@/shared/core/either';
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
    private readonly walletRepository: WalletRepository,
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
    if (isLeft(result)) return result;
    return result.value;
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
    const result = await this.walletRepository.getTransactions(userId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { transactions: result.value };
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
    const walletResult = await this.walletRepository.findByUserId(userId);
    if (walletResult.isLeft()) {
      return left(new AppError(walletResult.value.code, walletResult.value.message));
    }
    if (!walletResult.value) {
      return { withdrawals: [] };
    }

    const withdrawalsResult = await this.walletRepository.getWithdrawals(walletResult.value.id);
    if (withdrawalsResult.isLeft()) {
      return left(new AppError(withdrawalsResult.value.code, withdrawalsResult.value.message));
    }
    return { withdrawals: withdrawalsResult.value };
  }
}
