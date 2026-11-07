import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/users';
import { SuggestionResponse } from '../dtos/user-response.class';
import { GetSuggestionsInput } from '../dtos/user.dto';

@Injectable()
export class GetSuggestionsUseCase {
  constructor(private readonly userRepository: UserDatabaseRepository) {}

  async execute(input: GetSuggestionsInput): Promise<Either<AppError, { users: SuggestionResponse[]; hasMore: boolean; nextOffset: number | null }>> {
    const result = await this.userRepository.getSuggestions(input.userId, input.limit, input.offset);
    if (result.isLeft()) {
      return left(result.value);
    }
    const hasMore = result.value.length > input.limit;
    const users = result.value.slice(0, input.limit).map((u) => ({
      id: u.id,
      displayName: u.displayName,
      username: u.username,
      avatarUrl: u.avatarUrl,
      avatarBlurHash: u.avatarBlurHash,
      bio: u.bio,
      isVerified: u.isVerified,
      reputationScore: u.reputationScore,
      totalReviews: u.totalReviews,
      followersCount: u.followersCount,
      followingCount: u.followingCount,
      mutualCount: u.mutualCount,
    }));
    return right({ users, hasMore, nextOffset: hasMore ? input.offset + input.limit : null });
  }
}
