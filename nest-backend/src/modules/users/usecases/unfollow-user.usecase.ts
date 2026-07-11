import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { FollowRepository } from '../domain/repositories/follow.repository';
import { FollowResponse } from '../mappers/user.mapper';
import { FollowUserInput } from '../dtos/user.dto';

@Injectable()
export class UnfollowUserUseCase {
  constructor(
    private readonly followRepository: FollowRepository,
  ) {}

  async execute(input: FollowUserInput): Promise<Either<AppError, FollowResponse>> {
    const unfollowResult = await this.followRepository.unfollow(input.followerId, input.followingId);
    if (unfollowResult.isLeft()) return left(unfollowResult.value);

    const [followersCountResult, followingCountResult] = await Promise.all([
      this.followRepository.getFollowersCount(input.followingId),
      this.followRepository.getFollowingCount(input.followingId),
    ]);

    if (followersCountResult.isLeft()) return left(followersCountResult.value);
    if (followingCountResult.isLeft()) return left(followingCountResult.value);

    return right({ following: false, followersCount: followersCountResult.value, followingCount: followingCountResult.value });
  }
}
