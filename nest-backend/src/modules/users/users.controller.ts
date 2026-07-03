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
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  HttpCode,
  ParseUUIDPipe,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { FollowRepository } from './repositories/follow.repository';
import { BlockRepository } from './repositories/block.repository';
import { GetUserStatsUseCase } from './usecases';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import {
  UpdateProfileDTO,
  UpdateFcmTokenDTO,
  OffsetPaginationQueryDTO,
  UserSearchQueryDTO,
  SuggestionsQueryDTO,
} from './dtos/user.dto';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import {
  UserResponse,
  UserStatsResponse,
  FollowResponse,
  BlockResponse,
  toUserResponse,
} from './mappers/user.mapper';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { validateImageFile } from '@/shared/utils/image-upload.utils';

@ApiTags('Users')
@Controller('users')
export class UsersController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userRepository: UserRepository,
    private readonly followRepository: FollowRepository,
    private readonly blockRepository: BlockRepository,
    private readonly getUserStatsUseCase: GetUserStatsUseCase,
  ) {}

  @Get('me')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get current user profile',
    auth: true,
    responseType: UserResponse,
    errors: [{ status: 404, description: 'User not found' }],
  })
  async getMe(@CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const userResult = await this.userRepository.findById(userId);
    if (isLeft(userResult)) {
      return left(userResult.value);
    }
    if (!userResult.value) {
      return left(new AppError('NOT_FOUND', 'Usuário não encontrado'));
    }
    const userRecord = userResult.value;

    const [postsCount, productsCount, activeStory] = await Promise.all([
      this.prisma.post.count({ where: { userId } }),
      this.prisma.product.count({ where: { sellerId: userId, status: { not: 'DELETED' } } }),
      this.prisma.story.findFirst({
        where: { userId, expiresAt: { gt: new Date() } },
        select: { id: true },
      }),
    ]);

    return toUserResponse(userRecord, {
      postsCount,
      productsCount,
      hasActiveStory: activeStory !== null,
    });
  }

  @Get('me/stats')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get current user stats',
    auth: true,
    responseType: UserStatsResponse,
  })
  async getMyStats(@CurrentUser() user: AuthUser) {
    return this.getUserStatsUseCase.execute({ userId: user.userId });
  }

  @Patch('me')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Update profile',
    bodyType: UpdateProfileDTO,
    auth: true,
    responseType: UserResponse,
    errors: [{ status: 404, description: 'User not found' }],
  })
  async updateProfile(@CurrentUser() user: AuthUser, @Body() body: UpdateProfileDTO) {
    const userId = user.userId;
    const data = { ...body } as Record<string, unknown>;
    if (data.cpf) data.cpf = (data.cpf as string).replace(/\D/g, '');
    const updateResult = await this.userRepository.update(userId, data);
    if (isLeft(updateResult)) {
      return left(updateResult.value);
    }
    return toUserResponse(updateResult.value);
  }

  @Post('me/avatar')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @UseInterceptors(
    FileInterceptor('avatar', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  @ApiBearerAuth()
  @HttpCode(200)
  @ApiDoc({
    summary: 'Upload profile picture',
    description: 'Uploads an image to be used as profile avatar. Accepts JPEG, PNG, WebP, GIF up to 5MB.',
    auth: true,
    responseType: UserResponse,
  })
  async uploadAvatar(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('Imagem é obrigatória');
    }

    const mimeError = validateImageFile(file);
    if (mimeError) {
      throw new BadRequestException(mimeError);
    }

    const dataUri = `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
    const updateResult = await this.userRepository.update(user.userId, {
      avatarUrl: dataUri,
    });
    if (isLeft(updateResult)) {
      return left(updateResult.value);
    }
    return toUserResponse(updateResult.value);
  }

  @Patch('me/fcm-token')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Update FCM token',
    bodyType: UpdateFcmTokenDTO,
    auth: true,
  })
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

  // NOTE: static single-segment routes must be declared before the parametric
  // `@Get(':id')` below, otherwise Nest matches e.g. `/users/blocked` to `:id`
  // and ParseUUIDPipe rejects it ("Validation failed (uuid is expected)").
  @Get('blocked')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get blocked users',
    auth: true,
    queries: [
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
      { name: 'offset', required: false, description: 'Pagination offset (default 0)' },
    ],
  })
  async getBlockedUsers(
    @CurrentUser() user: AuthUser,
    @Query() query: OffsetPaginationQueryDTO,
  ) {
    const userId = user.userId;
    const parsedLimit = query.limit ?? 20;
    const parsedOffset = query.offset ?? 0;

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
  @ApiDoc({
    summary: 'Search users',
    queries: [
      { name: 'q', required: false, description: 'Search query' },
      { name: 'cursor', required: false, description: 'Pagination cursor' },
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
    ],
  })
  async searchUsers(@Query() query: UserSearchQueryDTO) {
    const parsedLimit = query.limit ?? 20;
    const searchResult = await this.userRepository.searchUsers(query.q || '', parsedLimit, query.cursor);
    if (isLeft(searchResult)) {
      return left(searchResult.value);
    }
    const users = searchResult.value;

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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get user suggestions',
    auth: true,
    queries: [
      { name: 'limit', required: false, description: 'Number of suggestions (default 10)' },
    ],
  })
  async getSuggestions(@CurrentUser() user: AuthUser, @Query() query: SuggestionsQueryDTO) {
    const userId = user.userId;
    const parsedLimit = query.limit ?? 10;
    const suggestionsResult = await this.userRepository.getSuggestions(userId, parsedLimit);
    if (isLeft(suggestionsResult)) {
      return left(suggestionsResult.value);
    }
    const suggestions = suggestionsResult.value;

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

  @Get(':id')
  @ApiDoc({
    summary: 'Get user by ID',
    params: [{ name: 'id', description: 'User UUID' }],
    responseType: UserResponse,
    errors: [{ status: 404, description: 'User not found' }],
  })
  async getUser(@Param('id', ParseUUIDPipe) id: string) {
    const userResult = await this.userRepository.findById(id);
    if (isLeft(userResult)) {
      return left(userResult.value);
    }
    if (!userResult.value) {
      return left(new AppError('NOT_FOUND', 'Usuário não encontrado'));
    }
    const userRecord = userResult.value;

    const [postsCount, productsCount, activeStory] = await Promise.all([
      this.prisma.post.count({ where: { userId: id } }),
      this.prisma.product.count({ where: { sellerId: id, status: { not: 'DELETED' } } }),
      this.prisma.story.findFirst({
        where: { userId: id, expiresAt: { gt: new Date() } },
        select: { id: true },
      }),
    ]);

    return toUserResponse(userRecord, {
      postsCount,
      productsCount,
      hasActiveStory: activeStory !== null,
    });
  }

  @Post(':id/follow')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Follow a user',
    auth: true,
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: FollowResponse,
    errors: [
      { status: 404, description: 'User not found' },
      { status: 409, description: 'Already following' },
    ],
  })
  async followUser(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUser() user: AuthUser) {
    const followerId = user.userId;

    if (followerId === followingId) {
      return left(new AppError('INVALID_OPERATION', 'Você não pode seguir a si mesmo'));
    }

    const targetResult = await this.userRepository.findById(followingId);
    if (isLeft(targetResult)) {
      return left(targetResult.value);
    }
    if (!targetResult.value) {
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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Unfollow a user',
    auth: true,
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: FollowResponse,
    errors: [{ status: 404, description: 'Not following' }],
  })
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

  @Get('me/followers')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get current user followers',
    auth: true,
  })
  async getMyFollowers(@CurrentUser() user: AuthUser) {
    const followers = await this.followRepository.getFollowers(user.userId, 20, 0);
    const total = await this.followRepository.getFollowersCount(user.userId);
    return {
      users: followers.map((u: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean }) => ({
        id: u.id,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isVerified: u.isVerified,
      })),
      total,
    };
  }

  @Get('me/following')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get current user following',
    auth: true,
  })
  async getMyFollowing(@CurrentUser() user: AuthUser) {
    const following = await this.followRepository.getFollowing(user.userId, 20, 0);
    const total = await this.followRepository.getFollowingCount(user.userId);
    return {
      users: following.map((u: { id: string; displayName: string; avatarUrl: string | null; isVerified: boolean }) => ({
        id: u.id,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isVerified: u.isVerified,
      })),
      total,
    };
  }

  @Get(':id/followers')
  @ApiDoc({
    summary: 'Get user followers',
    params: [{ name: 'id', description: 'User UUID' }],
    queries: [
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
      { name: 'offset', required: false, description: 'Pagination offset (default 0)' },
    ],
    errors: [{ status: 404, description: 'User not found' }],
  })
  async getFollowers(
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: OffsetPaginationQueryDTO,
  ) {
    const parsedLimit = query.limit ?? 20;
    const parsedOffset = query.offset ?? 0;

    const targetResult = await this.userRepository.findById(id);
    if (isLeft(targetResult)) {
      return left(targetResult.value);
    }
    if (!targetResult.value) {
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
  @ApiDoc({
    summary: 'Get users being followed',
    params: [{ name: 'id', description: 'User UUID' }],
    queries: [
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
      { name: 'offset', required: false, description: 'Pagination offset (default 0)' },
    ],
    errors: [{ status: 404, description: 'User not found' }],
  })
  async getFollowing(
    @Param('id', ParseUUIDPipe) id: string,
    @Query() query: OffsetPaginationQueryDTO,
  ) {
    const parsedLimit = query.limit ?? 20;
    const parsedOffset = query.offset ?? 0;

    const targetResult = await this.userRepository.findById(id);
    if (isLeft(targetResult)) {
      return left(targetResult.value);
    }
    if (!targetResult.value) {
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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Check if following a user',
    auth: true,
    params: [{ name: 'id', description: 'Target user UUID' }],
  })
  async isFollowing(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUser() user: AuthUser) {
    const followerId = user.userId;

    const isFollowing = await this.followRepository.isFollowing(followerId, followingId);
    const followersCount = await this.followRepository.getFollowersCount(followingId);
    const followingCount = await this.followRepository.getFollowingCount(followingId);

    return { isFollowing, followersCount, followingCount };
  }

  @Post(':id/block')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Block a user',
    auth: true,
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: BlockResponse,
    errors: [
      { status: 404, description: 'User not found' },
      { status: 409, description: 'Already blocked' },
    ],
  })
  async blockUser(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUser() user: AuthUser) {
    const blockerId = user.userId;

    if (blockerId === blockedId) {
      return left(new AppError('INVALID_OPERATION', 'Você não pode bloquear a si mesmo'));
    }

    const targetResult = await this.userRepository.findById(blockedId);
    if (isLeft(targetResult)) {
      return left(targetResult.value);
    }
    if (!targetResult.value) {
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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Unblock a user',
    auth: true,
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: BlockResponse,
    errors: [{ status: 404, description: 'Not blocked' }],
  })
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
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Check if a user is blocked',
    auth: true,
    params: [{ name: 'id', description: 'Target user UUID' }],
  })
  async isBlocked(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUser() user: AuthUser) {
    const blockerId = user.userId;

    const isBlocked = await this.blockRepository.isBlocked(blockerId, blockedId);
    return { isBlocked };
  }
}
