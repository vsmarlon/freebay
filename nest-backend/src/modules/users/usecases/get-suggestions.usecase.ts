import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { SuggestionResponse } from '../dtos/user-response.class';
import { GetSuggestionsInput } from '../dtos/user.dto';

@Injectable()
export class GetSuggestionsUseCase {
  constructor(private readonly userRepository: UserDatabaseRepository) {}

  async execute(input: GetSuggestionsInput): Promise<Either<AppError, SuggestionResponse[]>> {
    const result = await this.userRepository.getSuggestions(input.userId, input.limit);
    if (result.isLeft()) {
      return left(result.value);
    }
    return right(result.value.map((u) => ({
      id: u.id,
      displayName: u.displayName,
      username: u.username,
      avatarUrl: u.avatarUrl,
      bio: u.bio,
      isVerified: u.isVerified,
      reputationScore: u.reputationScore,
      totalReviews: u.totalReviews,
      followersCount: u.followersCount,
      followingCount: u.followingCount,
      mutualCount: u.mutualCount,
    })));
  }
}
