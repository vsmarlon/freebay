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
import { Throttle } from '@nestjs/throttler';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { FollowRepository } from './domain/repositories/follow.repository';
import { BlockRepository } from './domain/repositories/block.repository';
import { GetUserStatsUseCase, RegisterPhoneUseCase, VerifyPhoneUseCase } from './usecases';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import {
  UpdateProfileDTO,
  UpdateFcmTokenDTO,
  OffsetPaginationQueryDTO,
  UserSearchQueryDTO,
  SuggestionsQueryDTO,
  RegisterPhoneDTO,
  VerifyPhoneDTO,
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
    private readonly registerPhoneUseCase: RegisterPhoneUseCase,
    private readonly verifyPhoneUseCase: VerifyPhoneUseCase,
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
    }, true);
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
    if (body.username) {
      const existingResult = await this.userRepository.findByUsername(body.username);
      if (isLeft(existingResult)) return left(existingResult.value);
      if (existingResult.value && existingResult.value.id !== userId) {
        return left(new AppError('USERNAME_ALREADY_EXISTS', 'Este nome de usuário já está em uso', 409));
      }
    }
    const updateResult = await this.userRepository.update(userId, data);
    if (isLeft(updateResult)) {
      return left(updateResult.value);
    }
    return toUserResponse(updateResult.value, undefined, true);
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
    return toUserResponse(updateResult.value, undefined, true);
  }

  @Post('me/banner')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @UseInterceptors(
    FileInterceptor('banner', {
      storage: memoryStorage(),
      limits: { fileSize: 8 * 1024 * 1024 },
    }),
  )
  @ApiBearerAuth()
  @HttpCode(200)
  @ApiDoc({
    summary: 'Upload profile banner picture',
    description: 'Uploads an image to be used as profile banner. Accepts JPEG, PNG, WebP, GIF up to 8MB.',
    auth: true,
    responseType: UserResponse,
  })
  async uploadBanner(
    @CurrentUser() user: AuthUser,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException('Imagem é obrigatória');
    }

    const mimeError = validateImageFile(file, 8 * 1024 * 1024);
    if (mimeError) {
      throw new BadRequestException(mimeError);
    }

    const dataUri = `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
    const updateResult = await this.userRepository.update(user.userId, {
      bannerUrl: dataUri,
    });
    if (isLeft(updateResult)) {
      return left(updateResult.value);
    }
    return toUserResponse(updateResult.value, undefined, true);
  }

  @Post('me/phone')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @Throttle({ short: { limit: 3, ttl: 60000 }, medium: { limit: 5, ttl: 60000 } })
  @ApiBearerAuth()
  @HttpCode(200)
  @ApiDoc({
    summary: 'Register phone number for verification',
    bodyType: RegisterPhoneDTO,
    auth: true,
  })
  async registerPhone(@CurrentUser() user: AuthUser, @Body() body: RegisterPhoneDTO) {
    const result = await this.registerPhoneUseCase.execute({ userId: user.userId, phone: body.phone });
    if (isLeft(result)) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('me/phone/verify')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @Throttle({ short: { limit: 5, ttl: 60000 }, medium: { limit: 10, ttl: 60000 } })
  @ApiBearerAuth()
  @HttpCode(200)
  @ApiDoc({
    summary: 'Verify phone number using code',
    bodyType: VerifyPhoneDTO,
    auth: true,
  })
  async verifyPhone(@CurrentUser() user: AuthUser, @Body() body: VerifyPhoneDTO) {
    const result = await this.verifyPhoneUseCase.execute({ userId: user.userId, code: body.code });
    if (isLeft(result)) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Patch('me/fcm-token')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
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

    const result = await this.blockRepository.getBlockedUsers(userId, parsedLimit, parsedOffset);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));

    return {
      users: result.value.map((u) => ({
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
      { name: 'offset', required: false, description: 'Pagination offset (default 0)' },
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
    ],
  })
  async searchUsers(@CurrentUser() user: AuthUser, @Query() query: UserSearchQueryDTO) {
    const parsedLimit = query.limit ?? 20;
    const parsedOffset = query.offset ?? 0;
    const searchResult = await this.userRepository.searchUsers(
      query.q || '',
      parsedLimit,
      parsedOffset,
      user?.userId,
    );
    if (isLeft(searchResult)) {
      return left(searchResult.value);
    }
    const users = searchResult.value;

    return {
      users: users.map((u) => ({
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
      })),
      hasMore: users.length === parsedLimit,
      nextOffset: users.length === parsedLimit ? parsedOffset + parsedLimit : null,
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
        username: u.username,
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
  @HttpCode(200)
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

    const followResult = await this.followRepository.follow(followerId, followingId);
    if (followResult.isLeft()) return left(new AppError(followResult.value.code, followResult.value.message));

    const [followersCountResult, followingCountResult] = await Promise.all([
      this.followRepository.getFollowersCount(followingId),
      this.followRepository.getFollowingCount(followingId),
    ]);

    if (followersCountResult.isLeft()) return left(new AppError(followersCountResult.value.code, followersCountResult.value.message));
    if (followingCountResult.isLeft()) return left(new AppError(followingCountResult.value.code, followingCountResult.value.message));

    return { following: true, followersCount: followersCountResult.value, followingCount: followingCountResult.value };
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

    const unfollowResult = await this.followRepository.unfollow(followerId, followingId);
    if (unfollowResult.isLeft()) return left(new AppError(unfollowResult.value.code, unfollowResult.value.message));

    const [followersCountResult, followingCountResult] = await Promise.all([
      this.followRepository.getFollowersCount(followingId),
      this.followRepository.getFollowingCount(followingId),
    ]);

    if (followersCountResult.isLeft()) return left(new AppError(followersCountResult.value.code, followersCountResult.value.message));
    if (followingCountResult.isLeft()) return left(new AppError(followingCountResult.value.code, followingCountResult.value.message));

    return { following: false, followersCount: followersCountResult.value, followingCount: followingCountResult.value };
  }

  @Get('me/followers')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get current user followers',
    auth: true,
  })
  async getMyFollowers(@CurrentUser() user: AuthUser) {
    const followersResult = await this.followRepository.getFollowers(user.userId, 20, 0);
    if (followersResult.isLeft()) return left(new AppError(followersResult.value.code, followersResult.value.message));
    const totalResult = await this.followRepository.getFollowersCount(user.userId);
    if (totalResult.isLeft()) return left(new AppError(totalResult.value.code, totalResult.value.message));
    return {
      users: followersResult.value.map((u) => ({
        id: u.id,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isVerified: u.isVerified,
      })),
      total: totalResult.value,
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
    const followingResult = await this.followRepository.getFollowing(user.userId, 20, 0);
    if (followingResult.isLeft()) return left(new AppError(followingResult.value.code, followingResult.value.message));
    const totalResult = await this.followRepository.getFollowingCount(user.userId);
    if (totalResult.isLeft()) return left(new AppError(totalResult.value.code, totalResult.value.message));
    return {
      users: followingResult.value.map((u) => ({
        id: u.id,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isVerified: u.isVerified,
      })),
      total: totalResult.value,
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

    const followersResult = await this.followRepository.getFollowers(id, parsedLimit, parsedOffset);
    if (followersResult.isLeft()) return left(new AppError(followersResult.value.code, followersResult.value.message));
    const totalResult = await this.followRepository.getFollowersCount(id);
    if (totalResult.isLeft()) return left(new AppError(totalResult.value.code, totalResult.value.message));

    return {
      users: followersResult.value.map((u) => ({
        id: u.id,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isVerified: u.isVerified,
        reputationScore: u.reputationScore,
      })),
      total: totalResult.value,
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

    const followingResult = await this.followRepository.getFollowing(id, parsedLimit, parsedOffset);
    if (followingResult.isLeft()) return left(new AppError(followingResult.value.code, followingResult.value.message));
    const totalResult = await this.followRepository.getFollowingCount(id);
    if (totalResult.isLeft()) return left(new AppError(totalResult.value.code, totalResult.value.message));

    return {
      users: followingResult.value.map((u) => ({
        id: u.id,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        isVerified: u.isVerified,
        reputationScore: u.reputationScore,
      })),
      total: totalResult.value,
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

    const [isFollowingResult, followersCountResult, followingCountResult] = await Promise.all([
      this.followRepository.isFollowing(followerId, followingId),
      this.followRepository.getFollowersCount(followingId),
      this.followRepository.getFollowingCount(followingId),
    ]);

    if (isFollowingResult.isLeft()) return left(new AppError(isFollowingResult.value.code, isFollowingResult.value.message));
    if (followersCountResult.isLeft()) return left(new AppError(followersCountResult.value.code, followersCountResult.value.message));
    if (followingCountResult.isLeft()) return left(new AppError(followingCountResult.value.code, followingCountResult.value.message));

    return { isFollowing: isFollowingResult.value, followersCount: followersCountResult.value, followingCount: followingCountResult.value };
  }

  @Post(':id/block')
  @HttpCode(200)
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

    const blockResult = await this.blockRepository.block(blockerId, blockedId);
    if (blockResult.isLeft()) return left(new AppError(blockResult.value.code, blockResult.value.message));
    return { blocked: true };
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

    const unblockResult = await this.blockRepository.unblock(blockerId, blockedId);
    if (unblockResult.isLeft()) return left(new AppError(unblockResult.value.code, unblockResult.value.message));
    return { blocked: false };
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

    const isBlockedResult = await this.blockRepository.isBlocked(blockerId, blockedId);
    if (isBlockedResult.isLeft()) return left(new AppError(isBlockedResult.value.code, isBlockedResult.value.message));
    return { isBlocked: isBlockedResult.value };
  }
}
