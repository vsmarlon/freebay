import { Module } from '@nestjs/common';
import { WalletController } from './wallet.controller';
import { GetWalletUseCase } from './usecases/get-wallet.usecase';
import { WalletDatabaseRepository } from './data/repositories/wallet-database.repository';
import { WalletRepository } from './domain/repositories/wallet.repository';

@Module({
  controllers: [WalletController],
  providers: [
    GetWalletUseCase,
    WalletDatabaseRepository,
    { provide: WalletRepository, useExisting: WalletDatabaseRepository },
  ],
})
export class WalletModule {}
