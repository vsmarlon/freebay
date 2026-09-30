import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from './shared/guards/roles.guard';
import { OriginGuard } from './shared/guards/origin.guard';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { PUBLIC_UPLOAD_CONTEXTS } from './shared/utils/file.utils';
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
import { AdminModule } from './modules/admin/admin.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { FavoritesModule } from './modules/favorites/favorites.module';
import { CartModule } from './modules/cart/cart.module';
import { StoriesModule } from './modules/stories/stories.module';
import { TasksModule } from './modules/tasks/tasks.module';
import { BugReportModule } from './modules/bug-reports/bug-report.module';
import { UploadModule } from './modules/upload/upload.module';
import { MediaModule } from './modules/media/media.module';
import { HealthModule } from './modules/health/health.module';
import { THROTTLE_TTL_HOUR_MS, THROTTLE_TTL_MINUTE_MS, THROTTLE_TTL_SECOND_MS } from './shared/http/throttle.constants';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env'],
    }),
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        throttlers: [
          {
            name: 'short',
             ttl: THROTTLE_TTL_SECOND_MS,
            limit: config.get('THROTTLE_SHORT_LIMIT', 10),
          },
          {
            name: 'medium',
             ttl: THROTTLE_TTL_MINUTE_MS,
            limit: config.get('THROTTLE_MEDIUM_LIMIT', 60),
          },
          {
            name: 'long',
             ttl: THROTTLE_TTL_HOUR_MS,
            limit: config.get('THROTTLE_LONG_LIMIT', 1000),
          },
        ],
      }),
    }),
    // Only explicitly public contexts are mounted. Legacy /uploads/story files
    // stay on disk for authorized reads but cannot bypass story audience checks.
    ...PUBLIC_UPLOAD_CONTEXTS.map((context) => ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', '..', 'uploads', context),
      serveRoot: `/uploads/${context}`,
      serveStaticOptions: { index: false },
    })),
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', '..', 'legal'),
      serveRoot: '/legal',
      serveStaticOptions: { index: 'index.html', extensions: ['html'] },
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
    AdminModule,
    ReviewsModule,
    FavoritesModule,
    CartModule,
    StoriesModule,
    TasksModule,
    BugReportModule,
    UploadModule,
    MediaModule,
    HealthModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: RolesGuard,
    },
    {
      provide: APP_GUARD,
      useClass: OriginGuard,
    },
  ],
})
export class AppModule {}
