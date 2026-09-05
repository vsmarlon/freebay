import { Controller, Body, HttpStatus } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetWalletUseCase } from './usecases/get-wallet.usecase';
import { WithdrawUseCase } from './usecases/withdraw.usecase';
import { RegisterBankAccountUseCase } from './usecases/register-bank-account.usecase';
import { WithdrawDTO, BankAccountDTO, WalletResponse } from './dtos/wallet.dto';
import { WalletRepository } from './domain/repositories/wallet.repository';
import { GetAuth, PostAuth, CurrentUserId } from '@/shared/decorators';
import { isLeft } from '@/shared/core/either';

@ApiTags('Wallet')
@Controller('wallet')
export class WalletController {
  constructor(
    private readonly getWalletUseCase: GetWalletUseCase,
    private readonly withdrawUseCase: WithdrawUseCase,
    private readonly registerBankAccountUseCase: RegisterBankAccountUseCase,
    private readonly walletRepository: WalletRepository,
  ) {}

  @GetAuth({
    summary: 'Get wallet',
    description: 'Returns current wallet balance, pending balance, and available balance',
    responseType: WalletResponse,
  })
  async getWallet(@CurrentUserId() userId: string) {
    const result = await this.getWalletUseCase.execute(userId);
    if (isLeft(result)) return result;
    return result.value;
  }

  @PostAuth('withdraw', {
    summary: 'Request withdrawal',
    description: 'Request a PIX withdrawal from the wallet',
    bodyType: WithdrawDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
    errors: [{ status: 400, description: 'Insufficient balance or invalid data' }],
  })
  async withdraw(@CurrentUserId() userId: string, @Body() body: WithdrawDTO) {
    const result = await this.withdrawUseCase.execute({ userId, ...body });
    if (isLeft(result)) return result;
    return result.value;
  }

  @PostAuth('bank-account', {
    summary: 'Register bank account',
    description: 'Register a bank account for withdrawals',
    bodyType: BankAccountDTO,
    responseStatus: 201,
    httpCode: HttpStatus.CREATED,
  })
  async registerBankAccount(@CurrentUserId() userId: string, @Body() body: BankAccountDTO) {
    const result = await this.registerBankAccountUseCase.execute({ userId, ...body });
    if (isLeft(result)) return result;
    return result.value;
  }

  @GetAuth('transactions', {
    summary: 'Get transactions',
    description: 'Returns the transaction history for the wallet',
  })
  async getTransactions(@CurrentUserId() userId: string) {
    const result = await this.walletRepository.getTransactions(userId);
    if (isLeft(result)) return result;
    return { transactions: result.value };
  }

  @GetAuth('withdrawals', {
    summary: 'Get withdrawals',
    description: 'Returns the withdrawal history for the wallet',
  })
  async getWithdrawals(@CurrentUserId() userId: string) {
    const walletResult = await this.walletRepository.findByUserId(userId);
    if (isLeft(walletResult)) return walletResult;
    if (!walletResult.value) {
      return { withdrawals: [] };
    }

    const withdrawalsResult = await this.walletRepository.getWithdrawals(walletResult.value.id);
    if (isLeft(withdrawalsResult)) return withdrawalsResult;
    return { withdrawals: withdrawalsResult.value };
  }
}
