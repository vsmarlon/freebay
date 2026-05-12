import {
  Controller,
  Get,
  Patch,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaUserRepository } from '@/modules/auth/repositories/prisma-user.repository';
import { FollowRepository } from './repositories/follow.repository';
import { BlockRepository } from './repositories/block.repository';
import { GetUserStatsUseCase } from './usecases/user.usecase';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { updateProfileSchema, UpdateProfileDTO, UpdateFcmTokenDTO } from './dtos/user.dto';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { toUserResponse } from './mappers/user.mapper';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@Controller('users')
export class UsersController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userRepository: PrismaUserRepository,
    private readonly followRepository: FollowRepository,
    private readonly blockRepository: BlockRepository,
    private readonly getUserStatsUseCase: GetUserStatsUseCase,
  ) {}

  @Get('me')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async getMe(@CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const userRecord = await this.userRepository.findById(userId);
    if (!userRecord) {
      return left(new AppError('NOT_FOUND', 'Usuário não encontrado'));
    }
    return toUserResponse(userRecord);
  }

  @Get('me/stats')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async getMyStats(@CurrentUser() user: AuthUser) {
    return this.getUserStatsUseCase.execute({ userId: user.userId });
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async updateProfile(@CurrentUser() user: AuthUser, @Body() body: UpdateProfileDTO) {
    const userId = user.userId;
    const parsed = updateProfileSchema.safeParse(body);
    if (!parsed.success) {
      return left(new AppError('VALIDATION_ERROR', parsed.error.issues[0]?.message || 'Validation failed'));
    }

    const data = { ...parsed.data };
    if (data.cpf) data.cpf = data.cpf.replace(/\D/g, '');
    const updated = await this.userRepository.update(userId, data);
    return toUserResponse(updated);
  }

  @Patch('me/fcm-token')
  @UseGuards(JwtAuthGuard)
  async updateFcmToken(@CurrentUser() user: AuthUser, @Body() body: UpdateFcmTokenDTO) {
    const userId = user.userId;
    const updateData: Record<string, unknown> = {};
    if (body.fcmToken !== undefined) {
      updateData.fcmToken = body.fcmToken;
    }
    if (body.notificationPrefs !== undefined) {
      updateData.notificationPrefs = body.notificationPrefs as object;
    }

    if (Object.keys(updateData).length === 0) {
      return { success: true };
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: updateData,
    });

    return { success: true };
  }

  @Get(':id')
  async getUser(@Param('id', ParseUUIDPipe) id: string) {
    const userRecord = await this.userRepository.findById(id);
    if (!userRecord) {
      return left(new AppError('NOT_FOUND', 'Usuário não encontrado'));
    }
    return toUserResponse(userRecord);
  }

  @Post(':id/follow')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async followUser(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUser() user: AuthUser) {
    const followerId = user.userId;

    if (followerId === followingId) {
      return left(new AppError('INVALID_OPERATION', 'Você não pode seguir a si mesmo'));
    }

    const targetUser = await this.userRepository.findById(followingId);
    if (!targetUser) {
      return left(new AppError('NOT_FOUND', 'Usuário não encontrado'));
    }

    try {
      await this.followRepository.follow(followerId, followingId);
      const followersCount = await this.followRepository.getFollowersCount(followingId);
      const followingCount = await this.followRepository.getFollowingCount(followingId);
      return { following: true, followersCount, followingCount };
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2002') {
        return left(new AppError('ALREADY_FOLLOWING', 'Você já segue este usuário'));
      }
      throw error;
    }
  }

  @Delete(':id/follow')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async unfollowUser(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUser() user: AuthUser) {
    const followerId = user.userId;

    try {
      await this.followRepository.unfollow(followerId, followingId);
      const followersCount = await this.followRepository.getFollowersCount(followingId);
      const followingCount = await this.followRepository.getFollowingCount(followingId);
      return { following: false, followersCount, followingCount };
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2025') {
        return left(new AppError('NOT_FOLLOWING', 'Você não segue este usuário'));
      }
      throw error;
    }
  }

  @Get(':id/followers')
  async getFollowers(@Param('id', ParseUUIDPipe) id: string, @Query('limit') limit?: string, @Query('offset') offset?: string) {
    const parsedLimit = parseInt(limit || '20');
    const parsedOffset = parseInt(offset || '0');

    const targetUser = await this.userRepository.findById(id);
    if (!targetUser) {
      return left(new AppError('NOT_FOUND', 'Usuário não encontrado'));
    }

    const followers = await this.followRepository.getFollowers(id, parsedLimit, parsedOffset);
    const total = await this.followRepository.getFollowersCount(id);

    return {
      users: followers.map((u) => ({
        id: u.id,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isVerified: u.isVerified,
        reputationScore: u.reputationScore,
      })),
      total,
      limit: parsedLimit,
      offset: parsedOffset,
    };
  }

  @Get(':id/following')
  async getFollowing(@Param('id', ParseUUIDPipe) id: string, @Query('limit') limit?: string, @Query('offset') offset?: string) {
    const parsedLimit = parseInt(limit || '20');
    const parsedOffset = parseInt(offset || '0');

    const targetUser = await this.userRepository.findById(id);
    if (!targetUser) {
      return left(new AppError('NOT_FOUND', 'Usuário não encontrado'));
    }

    const following = await this.followRepository.getFollowing(id, parsedLimit, parsedOffset);
    const total = await this.followRepository.getFollowingCount(id);

    return {
      users: following.map((u) => ({
        id: u.id,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isVerified: u.isVerified,
        reputationScore: u.reputationScore,
      })),
      total,
      limit: parsedLimit,
      offset: parsedOffset,
    };
  }

  @Get(':id/is-following')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async isFollowing(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUser() user: AuthUser) {
    const followerId = user.userId;

    const isFollowing = await this.followRepository.isFollowing(followerId, followingId);
    const followersCount = await this.followRepository.getFollowersCount(followingId);
    const followingCount = await this.followRepository.getFollowingCount(followingId);

    return { isFollowing, followersCount, followingCount };
  }

  @Post(':id/block')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async blockUser(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUser() user: AuthUser) {
    const blockerId = user.userId;

    if (blockerId === blockedId) {
      return left(new AppError('INVALID_OPERATION', 'Você não pode bloquear a si mesmo'));
    }

    const targetUser = await this.userRepository.findById(blockedId);
    if (!targetUser) {
      return left(new AppError('NOT_FOUND', 'Usuário não encontrado'));
    }

    try {
      await this.blockRepository.block(blockerId, blockedId);
      return { blocked: true };
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2002') {
        return left(new AppError('ALREADY_BLOCKED', 'Usuário já bloqueado'));
      }
      throw error;
    }
  }

  @Delete(':id/block')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async unblockUser(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUser() user: AuthUser) {
    const blockerId = user.userId;

    try {
      await this.blockRepository.unblock(blockerId, blockedId);
      return { blocked: false };
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (err.code === 'P2025') {
        return left(new AppError('NOT_BLOCKED', 'Usuário não está bloqueado'));
      }
      throw error;
    }
  }

  @Get(':id/is-blocked')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async isBlocked(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUser() user: AuthUser) {
    const blockerId = user.userId;

    const isBlocked = await this.blockRepository.isBlocked(blockerId, blockedId);
    return { isBlocked };
  }

  @Get('blocked')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async getBlockedUsers(@CurrentUser() user: AuthUser, @Query('limit') limit?: string, @Query('offset') offset?: string) {
    const userId = user.userId;
    const parsedLimit = parseInt(limit || '20');
    const parsedOffset = parseInt(offset || '0');

    const blockedUsers = await this.blockRepository.getBlockedUsers(userId, parsedLimit, parsedOffset);

    return {
      users: blockedUsers.map((u) => ({
        id: u.id,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isVerified: u.isVerified,
        reputationScore: u.reputationScore,
      })),
      limit: parsedLimit,
      offset: parsedOffset,
    };
  }

  @Get('search')
  async searchUsers(@Query('q') query?: string, @Query('cursor') cursor?: string, @Query('limit') limit?: string) {
    const parsedLimit = parseInt(limit || '20');
    const users = await this.userRepository.searchUsers(query || '', parsedLimit, cursor);

    return {
      users: users.map((u) => ({
        id: u.id,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        bio: u.bio,
        isVerified: u.isVerified,
        reputationScore: u.reputationScore,
        totalReviews: u.totalReviews,
        followersCount: u._count?.followers || 0,
        followingCount: u._count?.following || 0,
      })),
      nextCursor: users.length === parsedLimit ? users[users.length - 1]?.id : null,
    };
  }

  @Get('suggestions')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async getSuggestions(@CurrentUser() user: AuthUser, @Query('limit') limit?: string) {
    const userId = user.userId;
    const parsedLimit = parseInt(limit || '10');
    const suggestions = await this.userRepository.getSuggestions(userId, parsedLimit);

    return {
      users: suggestions.map((u) => ({
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
      })),
    };
  }
}
