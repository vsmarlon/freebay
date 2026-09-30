import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { NotificationDatabaseRepository } from '@/modules/notifications/data/repositories/notification-database.repository';
import { UpdateFcmTokenInput } from '../dtos/user.dto';

@Injectable()
export class UpdateFcmTokenUseCase {
  constructor(private readonly notifications: NotificationDatabaseRepository) {}

  async execute(input: UpdateFcmTokenInput): Promise<Either<AppError, void>> {
    if (input.fcmToken !== undefined && !input.installationId) {
      return left(new BadRequestError('Identificador da instalação obrigatório'));
    }
    const userResult = await this.notifications.updatePushSettings(input.userId, input);
    if (userResult.isLeft()) {
      return left(userResult.value);
    }

    return right(undefined);
  }
}
