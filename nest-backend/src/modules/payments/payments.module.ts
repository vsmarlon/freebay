import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PaymentsController } from './payments.controller';
import { CreatePaymentSessionUseCase } from './usecases/create-payment-session.usecase';
import { CreatePaymentIntentUseCase } from './usecases/create-payment-intent.usecase';
import { ProcessWebhookUseCase } from './usecases/process-webhook.usecase';
import { ProcessRefundUseCase } from './usecases/process-refund.usecase';
import { SyncConnectAccountUseCase } from './usecases/sync-connect-account.usecase';
import { StartConnectOnboardingUseCase } from './usecases/start-connect-onboarding.usecase';
import { GetConnectStatusUseCase } from './usecases/get-connect-status.usecase';
import { GetConnectDashboardLinkUseCase } from './usecases/get-connect-dashboard-link.usecase';
import { SellerPayoutService } from './services/seller-payout.service';
import { StripeProvider } from './providers/stripe-provider';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaOrderRepository } from '../orders/data/repositories/order-database.repository';
import { OrderRepository } from '../orders/domain/repositories/order.repository';
import { ProductDatabaseRepository } from '../products/data/repositories/product-database.repository';
import { ProductRepository } from '../products/domain/repositories/product.repository';
import { TransactionDatabaseRepository } from './data/repositories/transaction-database.repository';
import { TransactionRepository } from './domain/repositories/transaction.repository';
import { ConnectAccountDatabaseRepository } from './data/repositories/connect-account-database.repository';
import { ConnectAccountRepository } from './domain/repositories/connect-account.repository';
import { PaymentGroupDatabaseRepository } from './data/repositories/payment-group-database.repository';
import { PaymentGroupRepository } from './domain/repositories/payment-group.repository';
import { ProcessGroupWebhookUseCase } from './usecases/process-group-webhook.usecase';
import { ExpireCheckoutGroupUseCase } from './usecases/expire-checkout-group.usecase';
import { WalletDatabaseRepository } from '../wallet/data/repositories/wallet-database.repository';
import { WalletRepository } from '../wallet/domain/repositories/wallet.repository';
import { UserDatabaseRepository } from '../auth/data/repositories/user-database.repository';
import { UserRepository } from '../auth/domain/repositories/user.repository';
import { WebhookGuard } from '@/shared/guards/webhook.guard';
import { WebhookDedupeInterceptor } from '@/shared/interceptors/webhook-dedupe.interceptor';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { PaymentProvider } from './domain/providers/payment-provider.interface';

@Module({
  imports: [ConfigModule],
  controllers: [PaymentsController],
  providers: [
    PrismaService,
    CreatePaymentSessionUseCase,
    CreatePaymentIntentUseCase,
    ProcessWebhookUseCase,
    ProcessRefundUseCase,
    SyncConnectAccountUseCase,
    StartConnectOnboardingUseCase,
    GetConnectStatusUseCase,
    GetConnectDashboardLinkUseCase,
    SellerPayoutService,
    StripeProvider,
    { provide: PaymentProvider, useExisting: StripeProvider },
    PrismaOrderRepository,
    { provide: OrderRepository, useExisting: PrismaOrderRepository },
    ProductDatabaseRepository,
    { provide: ProductRepository, useExisting: ProductDatabaseRepository },
    TransactionDatabaseRepository,
    { provide: TransactionRepository, useExisting: TransactionDatabaseRepository },
    ConnectAccountDatabaseRepository,
    { provide: ConnectAccountRepository, useExisting: ConnectAccountDatabaseRepository },
    PaymentGroupDatabaseRepository,
    { provide: PaymentGroupRepository, useExisting: PaymentGroupDatabaseRepository },
    ProcessGroupWebhookUseCase,
    ExpireCheckoutGroupUseCase,
    WalletDatabaseRepository,
    { provide: WalletRepository, useExisting: WalletDatabaseRepository },
    UserDatabaseRepository,
    { provide: UserRepository, useExisting: UserDatabaseRepository },
    WebhookGuard,
    WebhookDedupeInterceptor,
    RedisService,
  ],
  exports: [
    StripeProvider,
    PaymentProvider,
    CreatePaymentSessionUseCase,
    SellerPayoutService,
    ConnectAccountRepository,
    PaymentGroupRepository,
    ExpireCheckoutGroupUseCase,
    UserRepository,
  ],
})
export class PaymentsModule {}
