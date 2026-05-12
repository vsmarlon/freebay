import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { SharedModule } from './shared/shared.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { ProductsModule } from './modules/products/products.module';
import { CategoryModule } from './modules/category/category.module';
import { SocialModule } from './modules/social/social.module';
import { WalletModule } from './modules/wallet/wallet.module';
import { OrdersModule } from './modules/orders/orders.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { ChatModule } from './modules/chat/chat.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { DisputesModule } from './modules/disputes/disputes.module';
import { ReportsModule } from './modules/reports/reports.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { FavoritesModule } from './modules/favorites/favorites.module';
import { CartModule } from './modules/cart/cart.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        throttlers: [
          {
            name: 'short',
            ttl: 1000, // 1 second
            limit: config.get('THROTTLE_SHORT_LIMIT', 10),
          },
          {
            name: 'medium',
            ttl: 60000, // 1 minute
            limit: config.get('THROTTLE_MEDIUM_LIMIT', 60),
          },
          {
            name: 'long',
            ttl: 3600000, // 1 hour
            limit: config.get('THROTTLE_LONG_LIMIT', 1000),
          },
        ],
      }),
    }),
    SharedModule,
    AuthModule,
    UsersModule,
    ProductsModule,
    CategoryModule,
    SocialModule,
    WalletModule,
    OrdersModule,
    PaymentsModule,
    ChatModule,
    NotificationsModule,
    DisputesModule,
    ReportsModule,
    ReviewsModule,
    FavoritesModule,
    CartModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
