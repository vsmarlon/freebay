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
import { ProductDatabaseRepository } from '../products/data/repositories/product-database.repository';
import { TransactionDatabaseRepository } from './data/repositories/transaction-database.repository';
import { ConnectAccountDatabaseRepository } from './data/repositories/connect-account-database.repository';
import { PaymentGroupDatabaseRepository } from './data/repositories/payment-group-database.repository';
import { ProcessGroupWebhookUseCase } from './usecases/process-group-webhook.usecase';
import { ExpireCheckoutGroupUseCase } from './usecases/expire-checkout-group.usecase';
import { WalletDatabaseRepository } from '../wallet/data/repositories/wallet-database.repository';
import { UserDatabaseRepository } from '../auth/data/repositories/user-database.repository';
import { WebhookGuard } from '@/shared/guards/webhook.guard';
import { WebhookDedupeInterceptor } from '@/shared/interceptors/webhook-dedupe.interceptor';
import { RedisService } from '@/shared/infra/redis/redis.service';

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
    PrismaOrderRepository,
    ProductDatabaseRepository,
    TransactionDatabaseRepository,
    ConnectAccountDatabaseRepository,
    PaymentGroupDatabaseRepository,
    ProcessGroupWebhookUseCase,
    ExpireCheckoutGroupUseCase,
    WalletDatabaseRepository,
    UserDatabaseRepository,
    WebhookGuard,
    WebhookDedupeInterceptor,
    RedisService,
  ],
  exports: [
    StripeProvider,
    CreatePaymentSessionUseCase,
    SellerPayoutService,
    ConnectAccountDatabaseRepository,
    PaymentGroupDatabaseRepository,
    ExpireCheckoutGroupUseCase,
    UserDatabaseRepository,
  ],
})
export class PaymentsModule {}
