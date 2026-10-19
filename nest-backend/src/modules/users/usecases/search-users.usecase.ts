import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/users';
import { SearchUsersInput } from '../dtos/user.dto';

type SearchUser = {
  id: string;
  displayName: string;
  username: string | null;
  avatarUrl: string | null;
  avatarBlurHash: string | null;
  bio: string | null;
  isVerified: boolean;
  reputationScore: number;
  totalReviews: number;
  followersCount: number;
  followingCount: number;
};

@Injectable()
export class SearchUsersUseCase {
  constructor(private readonly userRepository: UserDatabaseRepository) {}

  async execute(input: SearchUsersInput): Promise<Either<AppError, { users: SearchUser[]; hasMore: boolean; nextOffset: number | null }>> {
    const result = await this.userRepository.searchUsers(input.query, input.limit, input.offset, input.viewerId);
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
    }));
    return right({ users, hasMore, nextOffset: hasMore ? input.offset + input.limit : null });
  }
}
