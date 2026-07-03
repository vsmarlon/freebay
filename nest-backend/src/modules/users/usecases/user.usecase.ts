import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { FollowRepository } from '../repositories/follow.repository';
import { NotificationService } from '../../notifications/services/notification.service';
import { BlockRepository } from '../repositories/block.repository';
import { PrismaOrderRepository } from '@/modules/orders/repositories/order.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import {
  UserResponse,
  UserStatsResponse,
  FollowResponse,
  BlockResponse,
  SearchUserResponse,
  SuggestionResponse,
  toUserResponse,
} from '../mappers/user.mapper';
import {
  GetProfileInput,
  GetUserStatsInput,
  UpdateProfileInput,
  UpdateFcmTokenInput,
  FollowUserInput,
  BlockUserInput,
  SearchUsersInput,
  GetSuggestionsInput,
} from '../dtos/user.dto';

@Injectable()
export class GetProfileUseCase {
  constructor(private userRepository: UserRepository) {}

  async execute(input: GetProfileInput): Promise<Either<AppError, UserResponse>> {
    const userResult = await this.userRepository.findById(input.userId);
    if (isLeft(userResult)) {
      return left(userResult.value);
    }
    if (!userResult.value) {
      return left(new NotFoundError('User'));
    }
    return right(toUserResponse(userResult.value));
  }
}

@Injectable()
export class GetUserStatsUseCase {
  constructor(
    private orderRepository: PrismaOrderRepository,
    private followRepository: FollowRepository,
  ) {}

  async execute(input: GetUserStatsInput): Promise<Either<AppError, UserStatsResponse>> {
    const [salesCountResult, purchasesCountResult] = await Promise.all([
      this.orderRepository.countBySellerId(input.userId),
      this.orderRepository.countByBuyerId(input.userId),
    ]);

    if (isLeft(salesCountResult)) return left(salesCountResult.value);
    if (isLeft(purchasesCountResult)) return left(purchasesCountResult.value);

    const [followersCount, followingCount] = await Promise.all([
      this.followRepository.getFollowersCount(input.userId),
      this.followRepository.getFollowingCount(input.userId),
    ]);

    return right({ salesCount: salesCountResult.value, purchasesCount: purchasesCountResult.value, followersCount, followingCount });
  }
}

@Injectable()
export class UpdateProfileUseCase {
  constructor(private userRepository: UserRepository) {}

  async execute(input: UpdateProfileInput): Promise<Either<AppError, UserResponse>> {
    const userResult = await this.userRepository.update(input.userId, input);
    if (isLeft(userResult)) {
      return left(userResult.value);
    }
    if (!userResult.value) {
      return left(new NotFoundError('User'));
    }
    return right(toUserResponse(userResult.value));
  }
}

@Injectable()
export class UpdateFcmTokenUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: UpdateFcmTokenInput): Promise<Either<AppError, { success: boolean }>> {
    const updateData: Record<string, unknown> = {};
    if (input.fcmToken !== undefined) {
      updateData.fcmToken = input.fcmToken;
    }
    if (input.notificationPrefs !== undefined) {
      updateData.notificationPrefs = input.notificationPrefs as object;
    }

    if (Object.keys(updateData).length === 0) {
      return right({ success: true });
    }

    await this.prisma.user.update({
      where: { id: input.userId },
      data: updateData,
    });

    return right({ success: true });
  }
}

@Injectable()
export class FollowUserUseCase {
  constructor(
    private userRepository: UserRepository,
    private followRepository: FollowRepository,
    private notificationService: NotificationService,
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
      throw error;
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

@Injectable()
export class UnfollowUserUseCase {
  constructor(
    private followRepository: FollowRepository,
  ) {}

  async execute(input: FollowUserInput): Promise<Either<AppError, FollowResponse>> {
    try {
      await this.followRepository.unfollow(input.followerId, input.followingId);
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2025') {
        return left(new BadRequestError('Not following'));
      }
      throw error;
    }

    const [followersCount, followingCount] = await Promise.all([
      this.followRepository.getFollowersCount(input.followingId),
      this.followRepository.getFollowingCount(input.followingId),
    ]);

    return right({ following: false, followersCount, followingCount });
  }
}

@Injectable()
export class BlockUserUseCase {
  constructor(
    private userRepository: UserRepository,
    private blockRepository: BlockRepository,
  ) {}

  async execute(input: BlockUserInput): Promise<Either<AppError, BlockResponse>> {
    if (input.blockerId === input.blockedId) {
      return left(new BadRequestError('Cannot block yourself'));
    }

    const targetResult = await this.userRepository.findById(input.blockedId);
    if (isLeft(targetResult)) {
      return left(targetResult.value);
    }
    if (!targetResult.value) {
      return left(new NotFoundError('User'));
    }

    try {
      await this.blockRepository.block(input.blockerId, input.blockedId);
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2002') {
        return left(new BadRequestError('Already blocked'));
      }
      throw error;
    }

    return right({ blocked: true });
  }
}

@Injectable()
export class UnblockUserUseCase {
  constructor(private blockRepository: BlockRepository) {}

  async execute(input: BlockUserInput): Promise<Either<AppError, BlockResponse>> {
    try {
      await this.blockRepository.unblock(input.blockerId, input.blockedId);
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2025') {
        return left(new BadRequestError('Not blocked'));
      }
      throw error;
    }

    return right({ blocked: false });
  }
}

@Injectable()
export class SearchUsersUseCase {
  constructor(private userRepository: UserRepository) {}

  async execute(input: SearchUsersInput): Promise<Either<AppError, SearchUserResponse[]>> {
    const result = await this.userRepository.searchUsers(input.query, input.limit, input.cursor);
    if (isLeft(result)) {
      return left(result.value);
    }
    return right(result.value.map((u) => ({
      id: u.id,
      displayName: u.displayName,
      avatarUrl: u.avatarUrl,
      bio: u.bio,
      isVerified: u.isVerified,
      reputationScore: u.reputationScore,
      totalReviews: u.totalReviews,
      followersCount: u._count?.followers || 0,
      followingCount: u._count?.following || 0,
    })));
  }
}

@Injectable()
export class GetSuggestionsUseCase {
  constructor(private userRepository: UserRepository) {}

  async execute(input: GetSuggestionsInput): Promise<Either<AppError, SuggestionResponse[]>> {
    const result = await this.userRepository.getSuggestions(input.userId, input.limit);
    if (isLeft(result)) {
      return left(result.value);
    }
    return right(result.value.map((u) => ({
      id: u.id,
      displayName: u.displayName,
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
