import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { JwtPayload } from '@/shared/core/types';
import { SessionTokenService } from '../services/session-token.service';
import { NotificationDatabaseRepository } from '@/modules/notifications/data/repositories/notification-database.repository';

@Injectable()
export class LogoutSessionUseCase {
  constructor(
    private readonly tokens: SessionTokenService,
    private readonly notifications: NotificationDatabaseRepository,
  ) {}

  async execute(payloads: Array<JwtPayload | undefined>, device?: { userId: string; installationId: string }): Promise<Either<AppError, { message: string }>> {
    await Promise.all(payloads.map((payload) => this.tokens.revoke(payload?.jti, payload?.exp)));
    if (device) {
      const removed = await this.notifications.removePushDevice(device.userId, device.installationId);
      if (removed.isLeft()) return left(removed.value);
    }
    return right({ message: 'Logout realizado' });
  }
}
