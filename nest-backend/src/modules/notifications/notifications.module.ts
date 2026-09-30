import { Global, Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsGateway } from './notifications.gateway';
import { FcmService } from './fcm.service';
import { NotificationService } from './services/notification.service';
import { GetNotificationsUseCase } from './usecases/get-notifications.usecase';
import { MarkAsReadUseCase } from './usecases/mark-as-read.usecase';
import { MarkAllAsReadUseCase } from './usecases/mark-all-as-read.usecase';
import { RegisterFcmTokenUseCase } from './usecases/register-fcm-token.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationDatabaseRepository } from './data/repositories/notification-database.repository';

@Global()
@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationsGateway,
    FcmService,
    NotificationService,
    GetNotificationsUseCase,
    MarkAsReadUseCase,
    MarkAllAsReadUseCase,
    RegisterFcmTokenUseCase,
    PrismaService,
    NotificationDatabaseRepository,
  ],
  exports: [NotificationService, FcmService, NotificationDatabaseRepository],
})
export class NotificationsModule {}
