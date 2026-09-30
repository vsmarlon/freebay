import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { SearchUserResponse } from '../dtos/user-response.class';
import { SearchUsersInput } from '../dtos/user.dto';

@Injectable()
export class SearchUsersUseCase {
  constructor(private readonly userRepository: UserDatabaseRepository) {}

  async execute(input: SearchUsersInput): Promise<Either<AppError, SearchUserResponse[]>> {
    const result = await this.userRepository.searchUsers(input.query, input.limit, input.offset, input.viewerId);
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
    })));
  }
}
