import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { FollowRepository } from '../repositories/follow.repository';
import { NotificationService } from '../../notifications/services/notification.service';
import { FollowResponse } from '../mappers/user.mapper';
import { FollowUserInput } from '../dtos/user.dto';

@Injectable()
export class FollowUserUseCase {
  constructor(
    private readonly userRepository: UserRepository,
    private readonly followRepository: FollowRepository,
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

    try {
      await this.followRepository.follow(input.followerId, input.followingId);
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2002') {
        return left(new BadRequestError('Already following'));
      }
      return left(new AppError('DB_ERROR', 'Erro ao seguir usuário'));
    }

    const followerResult = await this.userRepository.findById(input.followerId);
    if (!isLeft(followerResult) && followerResult.value) {
      await this.notificationService.notifyNewFollower(input.followingId, followerResult.value.displayName);
    }

    const [followersCount, followingCount] = await Promise.all([
      this.followRepository.getFollowersCount(input.followingId),
      this.followRepository.getFollowingCount(input.followingId),
    ]);

    return right({ following: true, followersCount, followingCount });
  }
}
