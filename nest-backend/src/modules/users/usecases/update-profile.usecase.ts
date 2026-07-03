import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { UserResponse, toUserResponse } from '../mappers/user.mapper';
import { UpdateProfileInput } from '../dtos/user.dto';

@Injectable()
export class UpdateProfileUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  async execute(input: UpdateProfileInput): Promise<Either<AppError, UserResponse>> {
    const userResult = await this.userRepository.update(input.userId, input);
    if (isLeft(userResult)) {
      return left(userResult.value);
    }
    if (!userResult.value) {
      return left(new NotFoundError('User'));
    }
    return right(toUserResponse(userResult.value));
  }
}
