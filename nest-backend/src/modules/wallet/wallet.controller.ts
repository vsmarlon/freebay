import { Controller } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetWalletUseCase } from './usecases/get-wallet.usecase';
import { WalletResponse } from './dtos/wallet.dto';
import { WalletDatabaseRepository } from './data/repositories/wallet-database.repository';
import { GetAuth, CurrentUserId, Paginated, PAGINATION_QUERIES } from '@/shared/decorators';
import { PageQuery } from '@/shared/core/pagination';

@ApiTags('Wallet')
@Controller('wallet')
export class WalletController {
  constructor(
    private readonly getWalletUseCase: GetWalletUseCase,
    private readonly walletRepository: WalletDatabaseRepository,
  ) {}

  @GetAuth({
    summary: 'Get wallet',
    description: 'Returns current wallet balance, pending balance, and available balance',
    responseType: WalletResponse,
  })
  async getWallet(@CurrentUserId() userId: string) {
    return this.getWalletUseCase.execute(userId);
  }

  @GetAuth('transactions', {
    summary: 'Get wallet statement',
    description: 'Cursor-paginated ledger entries that make up the wallet balance, newest first',
    queries: PAGINATION_QUERIES,
  })
  async getTransactions(@CurrentUserId() userId: string, @Paginated() page: PageQuery) {
    return this.walletRepository.getTransactions(userId, page);
  }
}
