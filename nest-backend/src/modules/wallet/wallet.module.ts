import { Module } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { WalletController } from './wallet.controller';
import { GetWalletUseCase } from './usecases/get-wallet.usecase';
import { WithdrawUseCase } from './usecases/withdraw.usecase';
import { RegisterBankAccountUseCase } from './usecases/register-bank-account.usecase';
import { WalletRepository } from './domain/repositories/wallet.repository';
import { WalletDatabaseRepository } from './data/repositories/wallet-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [WalletController],
  providers: [
    GetWalletUseCase,
    WithdrawUseCase,
    RegisterBankAccountUseCase,
    WalletDatabaseRepository,
    { provide: WalletRepository, useExisting: WalletDatabaseRepository },
    { provide: PrismaClient, useExisting: PrismaService },
    PrismaService,
  ],
})
export class WalletModule {}
