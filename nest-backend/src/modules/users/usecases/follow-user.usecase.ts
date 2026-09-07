import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { PrismaFollowRepository } from '../data/repositories/follow-database.repository';
import { NotificationService } from '../../notifications/services/notification.service';
import { FollowResponse } from '../mappers/user.mapper';
import { FollowUserInput } from '../dtos/user.dto';

@Injectable()
export class FollowUserUseCase {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly followRepository: PrismaFollowRepository,
    private readonly notificationService: NotificationService,
  ) {}

  async execute(input: FollowUserInput): Promise<Either<AppError, FollowResponse>> {
    if (input.followerId === input.followingId) {
      return left(new BadRequestError('Cannot follow yourself'));
    }

    const targetResult = await this.userRepository.findById(input.followingId);
    if (isLeft(targetResult)) {
      return left(targetResult.value);
    }
    if (!targetResult.value) {
      return left(new NotFoundError('User'));
    }

    const followResult = await this.followRepository.follow(input.followerId, input.followingId);
    if (followResult.isLeft()) return left(followResult.value);

    const followerResult = await this.userRepository.findById(input.followerId);
    if (!isLeft(followerResult) && followerResult.value) {
      await this.notificationService.notifyNewFollower(input.followingId, followerResult.value.displayName);
    }

    const [followersCountResult, followingCountResult] = await Promise.all([
      this.followRepository.getFollowersCount(input.followingId),
      this.followRepository.getFollowingCount(input.followingId),
    ]);

    if (followersCountResult.isLeft()) return left(followersCountResult.value);
    if (followingCountResult.isLeft()) return left(followingCountResult.value);

    return right({ following: true, followersCount: followersCountResult.value, followingCount: followingCountResult.value });
  }
}
