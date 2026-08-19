import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, UsernameAlreadyExistsError } from '@/shared/core/errors';
import { UserRepository } from '../domain/repositories/user.repository';
import { CompleteProfileDTO } from '../dtos/auth.dto';
import { AuthResponse, toAuthResponse } from '../mappers/auth.mapper';

@Injectable()
export class CompleteProfileUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  async execute(
    userId: string,
    input: CompleteProfileDTO,
  ): Promise<Either<AppError, AuthResponse>> {
    const userResult = await this.userRepository.findById(userId);
    if (userResult.isLeft()) return left(userResult.value);
    if (!userResult.value) {
      return left(new AppError('USER_NOT_FOUND', 'Usuário não encontrado', 404));
    }

    const user = userResult.value;

    // If username is already set and not a temp value, profile is complete
    if (user.username && !user.username.startsWith('g_')) {
      return right(toAuthResponse(user));
    }

    // Check username availability
    const existing = await this.userRepository.findByUsername(input.username);
    if (existing.isLeft()) return left(existing.value);
    if (existing.value) {
      return left(new UsernameAlreadyExistsError());
    }

    const updated = await this.userRepository.update(userId, {
      username: input.username,
      displayName: input.displayName ?? user.displayName,
      city: input.city ?? user.city,
      state: input.state ?? user.state,
    });
    if (updated.isLeft()) return left(updated.value);

    return right(toAuthResponse(updated.value));
  }
}
