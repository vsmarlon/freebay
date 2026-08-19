import {
  Controller,
  Get,
  Patch,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ApiTags } from '@nestjs/swagger';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { FollowRepository } from './domain/repositories/follow.repository';
import { BlockRepository } from './domain/repositories/block.repository';
import {
  GetUserStatsUseCase,
  RegisterPhoneUseCase,
  VerifyPhoneUseCase,
  GetProfileUseCase,
  UpdateProfileUseCase,
  UpdateFcmTokenUseCase,
  FollowUserUseCase,
  UnfollowUserUseCase,
  BlockUserUseCase,
  UnblockUserUseCase,
  SearchUsersUseCase,
  GetSuggestionsUseCase,
} from './usecases';
import { Authenticated } from '@/shared/decorators/endpoints.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import {
  UpdateProfileDTO,
  UpdateFcmTokenDTO,
  OffsetPaginationQueryDTO,
  UserSearchQueryDTO,
  SuggestionsQueryDTO,
  RegisterPhoneDTO,
  VerifyPhoneDTO,
} from './dtos/user.dto';
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
    private readonly userRepository: UserRepository,
    private readonly followRepository: FollowRepository,
    private readonly blockRepository: BlockRepository,
    private readonly getUserStatsUseCase: GetUserStatsUseCase,
    private readonly registerPhoneUseCase: RegisterPhoneUseCase,
    private readonly verifyPhoneUseCase: VerifyPhoneUseCase,
    private readonly getProfileUseCase: GetProfileUseCase,
    private readonly updateProfileUseCase: UpdateProfileUseCase,
    private readonly updateFcmTokenUseCase: UpdateFcmTokenUseCase,
    private readonly followUserUseCase: FollowUserUseCase,
    private readonly unfollowUserUseCase: UnfollowUserUseCase,
    private readonly blockUserUseCase: BlockUserUseCase,
    private readonly unblockUserUseCase: UnblockUserUseCase,
    private readonly searchUsersUseCase: SearchUsersUseCase,
    private readonly getSuggestionsUseCase: GetSuggestionsUseCase,
  ) {}

  @Get('me')
  @Authenticated({
    summary: 'Get current user profile',
    responseType: UserResponse,
    errors: [{ status: 404, description: 'User not found' }],
  })
  async getMe(@CurrentUser() user: AuthUser) {
    return this.getProfileUseCase.execute({ userId: user.userId, includePrivate: true });
  }

  @Get('me/stats')
  @Authenticated({
    summary: 'Get current user stats',
    responseType: UserStatsResponse,
  })
  async getMyStats(@CurrentUser() user: AuthUser) {
    return this.getUserStatsUseCase.execute({ userId: user.userId });
  }

  @Patch('me')
  @Authenticated({
    summary: 'Update profile',
    bodyType: UpdateProfileDTO,
    responseType: UserResponse,
    errors: [{ status: 404, description: 'User not found' }],
  })
  async updateProfile(@CurrentUser() user: AuthUser, @Body() body: UpdateProfileDTO) {
    return this.updateProfileUseCase.execute({ userId: user.userId, ...body });
  }

  @Post('me/avatar')
  @UseInterceptors(FileInterceptor('avatar', { storage: memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } }))
  @Authenticated({
    summary: 'Upload profile picture',
    description: 'Uploads an image to be used as profile avatar. Accepts JPEG, PNG, WebP, GIF up to 5MB.',
    responseType: UserResponse,
    httpCode: HttpStatus.OK,
  })
  async uploadAvatar(@CurrentUser() user: AuthUser, @UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Imagem é obrigatória');
    const mimeError = validateImageFile(file);
    if (mimeError) throw new BadRequestException(mimeError);

    const dataUri = `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
    const updateResult = await this.userRepository.update(user.userId, { avatarUrl: dataUri });
    if (isLeft(updateResult)) return left(updateResult.value);
    return toUserResponse(updateResult.value, undefined, true);
  }

  @Post('me/banner')
  @UseInterceptors(FileInterceptor('banner', { storage: memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 } }))
  @Authenticated({
    summary: 'Upload profile banner picture',
    description: 'Uploads an image to be used as profile banner. Accepts JPEG, PNG, WebP, GIF up to 8MB.',
    responseType: UserResponse,
    httpCode: HttpStatus.OK,
  })
  async uploadBanner(@CurrentUser() user: AuthUser, @UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Imagem é obrigatória');
    const mimeError = validateImageFile(file, 8 * 1024 * 1024);
    if (mimeError) throw new BadRequestException(mimeError);

    const dataUri = `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
    const updateResult = await this.userRepository.update(user.userId, { bannerUrl: dataUri });
    if (isLeft(updateResult)) return left(updateResult.value);
    return toUserResponse(updateResult.value, undefined, true);
  }

  @Post('me/phone')
  @Authenticated({
    summary: 'Register phone number for verification',
    bodyType: RegisterPhoneDTO,
    throttle: { short: { limit: 3, ttl: 60000 }, medium: { limit: 5, ttl: 60000 } },
    httpCode: HttpStatus.OK,
  })
  async registerPhone(@CurrentUser() user: AuthUser, @Body() body: RegisterPhoneDTO) {
    return this.registerPhoneUseCase.execute({ userId: user.userId, phone: body.phone });
  }

  @Post('me/phone/verify')
  @Authenticated({
    summary: 'Verify phone number using code',
    bodyType: VerifyPhoneDTO,
    throttle: { short: { limit: 5, ttl: 60000 }, medium: { limit: 10, ttl: 60000 } },
    httpCode: HttpStatus.OK,
  })
  async verifyPhone(@CurrentUser() user: AuthUser, @Body() body: VerifyPhoneDTO) {
    return this.verifyPhoneUseCase.execute({ userId: user.userId, code: body.code });
  }

  @Patch('me/fcm-token')
  @Authenticated({
    summary: 'Update FCM token',
    bodyType: UpdateFcmTokenDTO,
  })
  async updateFcmToken(@CurrentUser() user: AuthUser, @Body() body: UpdateFcmTokenDTO) {
    const result = await this.updateFcmTokenUseCase.execute({ userId: user.userId, ...body });
    if (isLeft(result)) return left(new AppError(result.value.code, result.value.message));
    return { success: true };
  }

  @Get('blocked')
  @Authenticated({
    summary: 'Get blocked users',
    queries: [
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
      { name: 'offset', required: false, description: 'Pagination offset (default 0)' },
    ],
  })
  async getBlockedUsers(@CurrentUser() user: AuthUser, @Query() query: OffsetPaginationQueryDTO) {
    const parsedLimit = query.limit ?? 20;
    const parsedOffset = query.offset ?? 0;
    const result = await this.blockRepository.getBlockedUsers(user.userId, parsedLimit, parsedOffset);
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
    const searchResult = await this.searchUsersUseCase.execute({
      query: query.q || '',
      limit: parsedLimit,
      offset: parsedOffset,
      viewerId: user?.userId,
    });
    if (isLeft(searchResult)) return left(new AppError(searchResult.value.code, searchResult.value.message));
    const users = searchResult.value;

    return {
      users,
      hasMore: users.length === parsedLimit,
      nextOffset: users.length === parsedLimit ? parsedOffset + parsedLimit : null,
    };
  }

  @Get('suggestions')
  @Authenticated({
    summary: 'Get user suggestions',
    queries: [{ name: 'limit', required: false, description: 'Number of suggestions (default 10)' }],
  })
  async getSuggestions(@CurrentUser() user: AuthUser, @Query() query: SuggestionsQueryDTO) {
    const suggestionsResult = await this.getSuggestionsUseCase.execute({
      userId: user.userId,
      limit: query.limit ?? 10,
    });
    if (isLeft(suggestionsResult)) return left(new AppError(suggestionsResult.value.code, suggestionsResult.value.message));
    return { users: suggestionsResult.value };
  }

  @Get(':id')
  @ApiDoc({
    summary: 'Get user by ID',
    params: [{ name: 'id', description: 'User UUID' }],
    responseType: UserResponse,
    errors: [{ status: 404, description: 'User not found' }],
  })
  async getUser(@Param('id', ParseUUIDPipe) id: string) {
    return this.getProfileUseCase.execute({ userId: id });
  }

  @Post(':id/follow')
  @Authenticated({
    summary: 'Follow a user',
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: FollowResponse,
    errors: [
      { status: 404, description: 'User not found' },
      { status: 409, description: 'Already following' },
    ],
    httpCode: HttpStatus.OK,
  })
  async followUser(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUser() user: AuthUser) {
    return this.followUserUseCase.execute({ followerId: user.userId, followingId });
  }

  @Delete(':id/follow')
  @Authenticated({
    summary: 'Unfollow a user',
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: FollowResponse,
    errors: [{ status: 404, description: 'Not following' }],
  })
  async unfollowUser(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUser() user: AuthUser) {
    return this.unfollowUserUseCase.execute({ followerId: user.userId, followingId });
  }

  @Get('me/followers')
  @Authenticated({ summary: 'Get current user followers' })
  async getMyFollowers(@CurrentUser() user: AuthUser) {
    return this.fetchFollowers(user.userId, 20, 0);
  }

  @Get('me/following')
  @Authenticated({ summary: 'Get current user following' })
  async getMyFollowing(@CurrentUser() user: AuthUser) {
    return this.fetchFollowing(user.userId, 20, 0);
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
  async getFollowers(@Param('id', ParseUUIDPipe) id: string, @Query() query: OffsetPaginationQueryDTO) {
    const userCheck = await this.ensureUserExists(id);
    if (userCheck) return userCheck;
    return this.fetchFollowers(id, query.limit ?? 20, query.offset ?? 0);
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
  async getFollowing(@Param('id', ParseUUIDPipe) id: string, @Query() query: OffsetPaginationQueryDTO) {
    const userCheck = await this.ensureUserExists(id);
    if (userCheck) return userCheck;
    return this.fetchFollowing(id, query.limit ?? 20, query.offset ?? 0);
  }

  @Get(':id/is-following')
  @Authenticated({
    summary: 'Check if following a user',
    params: [{ name: 'id', description: 'Target user UUID' }],
  })
  async isFollowing(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUser() user: AuthUser) {
    const [isFollowingResult, followersCountResult, followingCountResult] = await Promise.all([
      this.followRepository.isFollowing(user.userId, followingId),
      this.followRepository.getFollowersCount(followingId),
      this.followRepository.getFollowingCount(followingId),
    ]);

    if (isFollowingResult.isLeft()) return left(new AppError(isFollowingResult.value.code, isFollowingResult.value.message));
    if (followersCountResult.isLeft()) return left(new AppError(followersCountResult.value.code, followersCountResult.value.message));
    if (followingCountResult.isLeft()) return left(new AppError(followingCountResult.value.code, followingCountResult.value.message));

    return { isFollowing: isFollowingResult.value, followersCount: followersCountResult.value, followingCount: followingCountResult.value };
  }

  @Post(':id/block')
  @Authenticated({
    summary: 'Block a user',
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: BlockResponse,
    errors: [
      { status: 404, description: 'User not found' },
      { status: 409, description: 'Already blocked' },
    ],
    httpCode: HttpStatus.OK,
  })
  async blockUser(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUser() user: AuthUser) {
    return this.blockUserUseCase.execute({ blockerId: user.userId, blockedId });
  }

  @Delete(':id/block')
  @Authenticated({
    summary: 'Unblock a user',
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: BlockResponse,
    errors: [{ status: 404, description: 'Not blocked' }],
  })
  async unblockUser(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUser() user: AuthUser) {
    return this.unblockUserUseCase.execute({ blockerId: user.userId, blockedId });
  }

  @Get(':id/is-blocked')
  @Authenticated({
    summary: 'Check if a user is blocked',
    params: [{ name: 'id', description: 'Target user UUID' }],
  })
  async isBlocked(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUser() user: AuthUser) {
    const isBlockedResult = await this.blockRepository.isBlocked(user.userId, blockedId);
    if (isBlockedResult.isLeft()) return left(new AppError(isBlockedResult.value.code, isBlockedResult.value.message));
    return { isBlocked: isBlockedResult.value };
  }

  private async ensureUserExists(id: string) {
    const targetResult = await this.userRepository.findById(id);
    if (isLeft(targetResult)) return left(targetResult.value);
    if (!targetResult.value) return left(new AppError('NOT_FOUND', 'Usuário não encontrado'));
    return null;
  }

  private async fetchFollowers(userId: string, limit: number, offset: number) {
    const [followersResult, totalResult] = await Promise.all([
      this.followRepository.getFollowers(userId, limit, offset),
      this.followRepository.getFollowersCount(userId),
    ]);
    if (followersResult.isLeft()) return left(new AppError(followersResult.value.code, followersResult.value.message));
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
      limit,
      offset,
    };
  }

  private async fetchFollowing(userId: string, limit: number, offset: number) {
    const [followingResult, totalResult] = await Promise.all([
      this.followRepository.getFollowing(userId, limit, offset),
      this.followRepository.getFollowingCount(userId),
    ]);
    if (followingResult.isLeft()) return left(new AppError(followingResult.value.code, followingResult.value.message));
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
      limit,
      offset,
    };
  }
}
