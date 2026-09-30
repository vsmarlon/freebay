import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, UsernameAlreadyExistsError, UserNotFoundError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { CompleteProfileDTO } from '../dtos/auth.dto';
import { AuthSessionResponse } from '../dtos/auth-response.class';
import { toUserResponse } from '../../users/dtos/user-response.class';

@Injectable()
export class CompleteProfileUseCase {
  constructor(private readonly userRepository: UserDatabaseRepository) {}

  async execute(
    userId: string,
    input: CompleteProfileDTO,
  ): Promise<Either<AppError, Pick<AuthSessionResponse, 'user'>>> {
    const userResult = await this.userRepository.findById(userId);
    if (userResult.isLeft()) return left(userResult.value);
    if (!userResult.value) {
      return left(new UserNotFoundError());
    }

    const user = userResult.value;

    // If username is already set and not a temp value, profile is complete
    if (user.username && !user.username.startsWith('g_')) {
      return right({ user: toUserResponse(user, undefined, true) });
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

    return right({ user: toUserResponse(updated.value, undefined, true) });
  }
}
