import { Global, Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsDevController } from './notifications-dev.controller';
import { NotificationsGateway } from './notifications.gateway';
import { FcmService } from './fcm.service';
import { NotificationService } from './services/notification.service';
import { GetNotificationsUseCase } from './usecases/get-notifications.usecase';
import { MarkAsReadUseCase } from './usecases/mark-as-read.usecase';
import { MarkAllAsReadUseCase } from './usecases/mark-all-as-read.usecase';
import { RegisterFcmTokenUseCase } from './usecases/register-fcm-token.usecase';
import { PushTestUseCase } from './usecases/push-test.usecase';
import { NotificationDatabaseRepository } from './data/repositories/notification-database.repository';

/** True only for a production process; dev/test keep the diagnostic routes. */
export function isProductionEnvironment(nodeEnv: string | undefined): boolean {
  return (nodeEnv ?? process.env.NODE_ENV ?? 'development') === 'production';
}

// Dev-only diagnostic routing is absent from a production process at registration time.
// The controller handler itself still 404s on production as a fail-closed backstop.
const devControllers = isProductionEnvironment(process.env.NODE_ENV) ? [] : [NotificationsDevController];

@Global()
@Module({
  controllers: [NotificationsController, ...devControllers],
  providers: [
    NotificationsGateway,
    FcmService,
    NotificationService,
    GetNotificationsUseCase,
    MarkAsReadUseCase,
    MarkAllAsReadUseCase,
    RegisterFcmTokenUseCase,
    PushTestUseCase,
    NotificationDatabaseRepository,
  ],
  exports: [NotificationService, FcmService, NotificationDatabaseRepository, NotificationsGateway],
})
export class NotificationsModule {}
