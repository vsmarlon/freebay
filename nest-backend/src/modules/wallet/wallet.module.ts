import { Module } from '@nestjs/common';
import { WalletController } from './wallet.controller';
import { GetWalletUseCase, WithdrawUseCase, RegisterBankAccountUseCase } from './usecases/wallet.usecase';
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
