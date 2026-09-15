import { Module } from '@nestjs/common';
import { WalletController } from './wallet.controller';
import { GetWalletUseCase } from './usecases/get-wallet.usecase';
import { WalletDatabaseRepository } from './data/repositories/wallet-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { WalletRepository } from './domain/repositories/wallet.repository';

@Module({
  controllers: [WalletController],
  providers: [
    GetWalletUseCase,
    WalletDatabaseRepository,
    { provide: WalletRepository, useExisting: WalletDatabaseRepository },
    PrismaService,
  ],
})
export class WalletModule {}
