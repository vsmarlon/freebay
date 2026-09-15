import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { UserResponse, toUserResponse } from '../mappers/user.mapper';
import { GetProfileInput } from '../dtos/user.dto';

@Injectable()
export class GetProfileUseCase {
  constructor(private readonly userRepository: UserDatabaseRepository) {}

  async execute(input: GetProfileInput): Promise<Either<AppError, UserResponse>> {
    const userResult = await this.userRepository.findById(input.userId);
    if (userResult.isLeft()) {
      return left(userResult.value);
    }
    if (!userResult.value) {
      return left(new NotFoundError('User'));
    }

    const countsResult = await this.userRepository.getProfileCounts(input.userId);
    if (countsResult.isLeft()) {
      return left(countsResult.value);
    }

    return right(toUserResponse(userResult.value, countsResult.value, input.includePrivate));
  }
}
