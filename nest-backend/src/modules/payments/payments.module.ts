import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaClient } from '@prisma/client';
import { PaymentsController } from './payments.controller';
import { CreatePixPaymentUseCase } from './usecases/create-pix-payment.usecase';
import { ProcessWebhookUseCase } from './usecases/process-webhook.usecase';
import { AbacatePayProvider } from './providers/abacatepay.provider';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaOrderRepository } from '../orders/repositories/order.repository';
import { OrderRepository } from '../orders/domain/repositories/order.repository';
import { ProductDatabaseRepository } from '../products/data/repositories/product-database.repository';
import { ProductRepository } from '../products/domain/repositories/product.repository';
import { TransactionDatabaseRepository } from './data/repositories/transaction-database.repository';
import { TransactionRepository } from './domain/repositories/transaction.repository';
import { WalletDatabaseRepository } from '../wallet/data/repositories/wallet-database.repository';
import { WalletRepository } from '../wallet/domain/repositories/wallet.repository';
import { UserDatabaseRepository } from '../auth/data/repositories/user-database.repository';
import { UserRepository } from '../auth/domain/repositories/user.repository';
import { WebhookGuard } from '@/shared/guards/webhook.guard';
import { RedisService } from '@/shared/infra/redis/redis.service';

@Module({
  imports: [ConfigModule],
  controllers: [PaymentsController],
  providers: [
    CreatePixPaymentUseCase,
    ProcessWebhookUseCase,
    AbacatePayProvider,
    PrismaService,
    { provide: PrismaClient, useExisting: PrismaService },
    PrismaOrderRepository,
    { provide: OrderRepository, useExisting: PrismaOrderRepository },
    ProductDatabaseRepository,
    { provide: ProductRepository, useExisting: ProductDatabaseRepository },
    TransactionDatabaseRepository,
    { provide: TransactionRepository, useExisting: TransactionDatabaseRepository },
    WalletDatabaseRepository,
    { provide: WalletRepository, useExisting: WalletDatabaseRepository },
    UserDatabaseRepository,
    { provide: UserRepository, useExisting: UserDatabaseRepository },
    WebhookGuard,
    RedisService,
  ],
  exports: [AbacatePayProvider, CreatePixPaymentUseCase],
})
export class PaymentsModule {}
