import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { USERNAME_REGEX } from '../dtos/auth.dto';

export interface CheckUsernameAvailabilityInput {
  username: string;
}

export interface CheckUsernameAvailabilityOutput {
  available: boolean;
}

@Injectable()
export class CheckUsernameAvailabilityUseCase {
  constructor(private readonly userRepository: UserDatabaseRepository) {}

  async execute(
    input: CheckUsernameAvailabilityInput,
  ): Promise<Either<AppError, CheckUsernameAvailabilityOutput>> {
    const username = (input?.username || '').toLowerCase().trim();
    if (!username || !USERNAME_REGEX.test(username)) {
      return right({ available: false });
    }

    const existingResult = await this.userRepository.findByUsername(username);
    if (existingResult.isLeft()) return left(existingResult.value);

    return right({ available: existingResult.value === null });
  }
}
