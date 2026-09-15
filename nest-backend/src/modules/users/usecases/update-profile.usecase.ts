import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UsernameAlreadyExistsError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { UserResponse, toUserResponse } from '../mappers/user.mapper';
import { UpdateProfileInput } from '../dtos/user.dto';

@Injectable()
export class UpdateProfileUseCase {
  constructor(private readonly userRepository: UserDatabaseRepository) {}

  async execute(input: UpdateProfileInput): Promise<Either<AppError, UserResponse>> {
    const { userId, ...data } = input;
    const updateData = { ...data } as Record<string, unknown>;
    if (updateData.cpf) updateData.cpf = (updateData.cpf as string).replace(/\D/g, '');

    if (input.username) {
      const existingResult = await this.userRepository.findByUsername(input.username);
      if (existingResult.isLeft()) return left(existingResult.value);
      if (existingResult.value && existingResult.value.id !== userId) {
        return left(new UsernameAlreadyExistsError());
      }
    }

    const userResult = await this.userRepository.update(userId, updateData);
    if (userResult.isLeft()) {
      return left(userResult.value);
    }
    if (!userResult.value) {
      return left(new NotFoundError('User'));
    }
    return right(toUserResponse(userResult.value, undefined, true));
  }
}
