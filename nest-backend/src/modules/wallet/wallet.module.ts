import { Module } from '@nestjs/common';
import { WalletController } from './wallet.controller';
import { GetWalletUseCase } from './usecases/get-wallet.usecase';
import { WithdrawUseCase } from './usecases/withdraw.usecase';
import { RegisterBankAccountUseCase } from './usecases/register-bank-account.usecase';
import { PrismaWalletRepository } from './repositories/wallet.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [WalletController],
  providers: [
    GetWalletUseCase,
    WithdrawUseCase,
    RegisterBankAccountUseCase,
    PrismaWalletRepository,
    PrismaService,
  ],
})
export class WalletModule {}
