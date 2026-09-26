import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { FollowRepository } from '../domain/repositories/follow.repository';

@Injectable()
export class GetFollowStatusUseCase {
  constructor(private readonly followRepository: FollowRepository) {}

  async execute(input: { followerId: string; followingId: string }): Promise<Either<AppError, { isFollowing: boolean; followersCount: number; followingCount: number }>> {
    const [isFollowingResult, followersCountResult, followingCountResult] = await Promise.all([
      this.followRepository.isFollowing(input.followerId, input.followingId),
      this.followRepository.getFollowersCount(input.followingId),
      this.followRepository.getFollowingCount(input.followingId),
    ]);
    if (isFollowingResult.isLeft()) return left(isFollowingResult.value);
    if (followersCountResult.isLeft()) return left(followersCountResult.value);
    if (followingCountResult.isLeft()) return left(followingCountResult.value);
    return right({ isFollowing: isFollowingResult.value, followersCount: followersCountResult.value, followingCount: followingCountResult.value });
  }
}
