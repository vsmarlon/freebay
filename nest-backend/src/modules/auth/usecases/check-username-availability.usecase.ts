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
  suggestions: string[];
}

@Injectable()
export class CheckUsernameAvailabilityUseCase {
  constructor(private readonly userRepository: UserDatabaseRepository) {}

  async execute(
    input: CheckUsernameAvailabilityInput,
  ): Promise<Either<AppError, CheckUsernameAvailabilityOutput>> {
    const username = (input?.username || '').toLowerCase().trim();
    if (!username || !USERNAME_REGEX.test(username)) {
      return right({ available: false, suggestions: [] });
    }

    const existingResult = await this.userRepository.findByUsername(username);
    if (existingResult.isLeft()) return left(existingResult.value);

    if (!existingResult.value) return right({ available: true, suggestions: [] });

    const candidates = Array.from({ length: 12 }, (_, index) => {
      const suffix = `_${index + 1}`;
      return `${username.slice(0, 20 - suffix.length)}${suffix}`;
    });
    const taken = await this.userRepository.findTakenUsernames(candidates);
    if (taken.isLeft()) return left(taken.value);

    const unavailable = new Set(taken.value);
    return right({
      available: false,
      suggestions: candidates.filter((candidate) => !unavailable.has(candidate)).slice(0, 3),
    });
  }
}
