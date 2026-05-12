import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PrismaUserRepository } from '@/modules/auth/repositories/prisma-user.repository';
import { FollowRepository } from '../repositories/follow.repository';
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
  constructor(private userRepository: PrismaUserRepository) {}

  async execute(input: GetProfileInput): Promise<Either<AppError, UserResponse>> {
    const user = await this.userRepository.findById(input.userId);
    if (!user) {
      return left(new NotFoundError('User'));
    }

    return right(toUserResponse(user));
  }
}

@Injectable()
export class GetUserStatsUseCase {
  constructor(
    private orderRepository: PrismaOrderRepository,
    private followRepository: FollowRepository,
  ) {}

  async execute(input: GetUserStatsInput): Promise<UserStatsResponse> {
    const [salesCount, purchasesCount, followersCount, followingCount] = await Promise.all([
      this.orderRepository.countBySellerId(input.userId),
      this.orderRepository.countByBuyerId(input.userId),
      this.followRepository.getFollowersCount(input.userId),
      this.followRepository.getFollowingCount(input.userId),
    ]);

    return { salesCount, purchasesCount, followersCount, followingCount };
  }
}

@Injectable()
export class UpdateProfileUseCase {
  constructor(private userRepository: PrismaUserRepository) {}

  async execute(input: UpdateProfileInput): Promise<Either<AppError, UserResponse>> {
    const user = await this.userRepository.update(input.userId, input);
    if (!user) {
      return left(new NotFoundError('User'));
    }

    return right(toUserResponse(user));
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
    private userRepository: PrismaUserRepository,
    private followRepository: FollowRepository,
  ) {}

  async execute(input: FollowUserInput): Promise<Either<AppError, FollowResponse>> {
    if (input.followerId === input.followingId) {
      return left(new BadRequestError('Cannot follow yourself'));
    }

    const targetUser = await this.userRepository.findById(input.followingId);
    if (!targetUser) {
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

    const followersCount = await this.followRepository.getFollowersCount(input.followingId);
    const followingCount = await this.followRepository.getFollowingCount(input.followingId);

    return right({ following: true, followersCount, followingCount });
  }
}

@Injectable()
export class UnfollowUserUseCase {
  constructor(
    private userRepository: PrismaUserRepository,
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

    const followersCount = await this.followRepository.getFollowersCount(input.followingId);
    const followingCount = await this.followRepository.getFollowingCount(input.followingId);

    return right({ following: false, followersCount, followingCount });
  }
}

@Injectable()
export class BlockUserUseCase {
  constructor(
    private userRepository: PrismaUserRepository,
    private blockRepository: BlockRepository,
  ) {}

  async execute(input: BlockUserInput): Promise<Either<AppError, BlockResponse>> {
    if (input.blockerId === input.blockedId) {
      return left(new BadRequestError('Cannot block yourself'));
    }

    const targetUser = await this.userRepository.findById(input.blockedId);
    if (!targetUser) {
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
  constructor(private userRepository: PrismaUserRepository) {}

  async execute(input: SearchUsersInput): Promise<SearchUserResponse[]> {
    const users = await this.userRepository.searchUsers(input.query, input.limit, input.cursor);

    return users.map((u) => ({
      id: u.id,
      displayName: u.displayName,
      avatarUrl: u.avatarUrl,
      bio: u.bio,
      isVerified: u.isVerified,
      reputationScore: u.reputationScore,
      totalReviews: u.totalReviews,
      followersCount: u._count?.followers || 0,
      followingCount: u._count?.following || 0,
    }));
  }
}

@Injectable()
export class GetSuggestionsUseCase {
  constructor(private userRepository: PrismaUserRepository) {}

  async execute(input: GetSuggestionsInput): Promise<SuggestionResponse[]> {
    const suggestions = await this.userRepository.getSuggestions(input.userId, input.limit);

    return suggestions.map((u) => ({
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
    }));
  }
}
