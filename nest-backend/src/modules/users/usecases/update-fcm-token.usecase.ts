import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { UpdateFcmTokenInput } from '../dtos/user.dto';

@Injectable()
export class UpdateFcmTokenUseCase {
  constructor(private readonly userRepository: UserDatabaseRepository) {}

  async execute(input: UpdateFcmTokenInput): Promise<Either<AppError, void>> {
    const updateData: Record<string, unknown> = {};
    if (input.fcmToken !== undefined) {
      updateData.fcmToken = input.fcmToken;
    }
    if (input.notificationPrefs !== undefined) {
      updateData.notificationPrefs = input.notificationPrefs as object;
    }

    if (Object.keys(updateData).length === 0) {
      return right(undefined);
    }

    const userResult = await this.userRepository.update(input.userId, updateData);
    if (isLeft(userResult)) {
      return left(userResult.value);
    }

    return right(undefined);
  }
}
