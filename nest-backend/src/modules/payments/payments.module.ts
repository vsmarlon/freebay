import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PaymentsController } from './payments.controller';
import { CreatePaymentSessionUseCase } from './usecases/create-payment-session.usecase';
import { CreatePaymentIntentUseCase } from './usecases/create-payment-intent.usecase';
import { CreateCryptoPaymentUseCase } from './usecases/create-crypto-payment.usecase';
import { ProcessWebhookUseCase } from './usecases/process-webhook.usecase';
import { StripeProvider } from './providers/stripe-provider';
import { MoneroRpcProvider } from './providers/monero-rpc.provider';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaOrderRepository } from '../orders/data/repositories/order-database.repository';
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
import { WebhookDedupeInterceptor } from '@/shared/interceptors/webhook-dedupe.interceptor';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { PaymentProvider } from './domain/providers/payment-provider.interface';
import { CryptoPaymentProvider } from './domain/providers/crypto-payment.provider.interface';

@Module({
  imports: [ConfigModule],
  controllers: [PaymentsController],
  providers: [
    PrismaService,
    // Use cases
    CreatePaymentSessionUseCase,
    CreatePaymentIntentUseCase,
    CreateCryptoPaymentUseCase,
    ProcessWebhookUseCase,
    // Payment providers
    StripeProvider,
    { provide: PaymentProvider, useExisting: StripeProvider },
    MoneroRpcProvider,
    { provide: CryptoPaymentProvider, useExisting: MoneroRpcProvider },
    // Order repository (abstract ↔ concrete binding)
    PrismaOrderRepository,
    { provide: OrderRepository, useExisting: PrismaOrderRepository },
    // Product repository
    ProductDatabaseRepository,
    { provide: ProductRepository, useExisting: ProductDatabaseRepository },
    // Transaction repository
    TransactionDatabaseRepository,
    { provide: TransactionRepository, useExisting: TransactionDatabaseRepository },
    // Wallet repository
    WalletDatabaseRepository,
    { provide: WalletRepository, useExisting: WalletDatabaseRepository },
    // User repository
    UserDatabaseRepository,
    { provide: UserRepository, useExisting: UserDatabaseRepository },
    // Infrastructure
    WebhookGuard,
    WebhookDedupeInterceptor,
    RedisService,
  ],
  exports: [StripeProvider, MoneroRpcProvider, CreatePaymentSessionUseCase, CreateCryptoPaymentUseCase],
})
export class PaymentsModule {}
