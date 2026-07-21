import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { SearchUserResponse } from '../mappers/user.mapper';
import { SearchUsersInput } from '../dtos/user.dto';

@Injectable()
export class SearchUsersUseCase {
  constructor(private readonly userRepository: UserRepository) {}

  async execute(input: SearchUsersInput): Promise<Either<AppError, SearchUserResponse[]>> {
    const result = await this.userRepository.searchUsers(input.query, input.limit, input.offset, input.viewerId);
    if (isLeft(result)) {
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
