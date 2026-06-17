import { Global, Module } from '@nestjs/common';
import { NotificationsController } from './notifications.controller';
import { NotificationsGateway } from './notifications.gateway';
import { FcmService } from './fcm.service';
import { NotificationService } from './services/notification.service';
import {
  GetNotificationsUseCase,
  MarkAsReadUseCase,
  RegisterFcmTokenUseCase,
} from './usecases/notification.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Global()
@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationsGateway,
    FcmService,
    NotificationService,
    GetNotificationsUseCase,
    MarkAsReadUseCase,
    RegisterFcmTokenUseCase,
    PrismaService,
  ],
  exports: [NotificationService, FcmService],
})
export class NotificationsModule {}
