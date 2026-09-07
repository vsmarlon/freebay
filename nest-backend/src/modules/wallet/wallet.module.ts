import { Module } from '@nestjs/common';
import { WalletController } from './wallet.controller';
import { GetWalletUseCase } from './usecases/get-wallet.usecase';
import { WalletDatabaseRepository } from './data/repositories/wallet-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [WalletController],
  providers: [
    GetWalletUseCase,
    WalletDatabaseRepository,
    WalletDatabaseRepository,
    PrismaService,
  ],
})
export class WalletModule {}
