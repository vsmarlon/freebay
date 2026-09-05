import {
  Controller,
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
import {
  GetAuth,
  GetPublic,
  PostAuth,
  PatchAuth,
  CurrentUserId,
} from '@/shared/decorators';
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
import { left, isLeft } from '@/shared/core/either';
import { NotFoundError } from '@/shared/core/errors';
import { validateImageFile } from '@/shared/utils/image-upload.utils';
import { saveUpload } from '@/shared/utils/file.utils';

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

  @GetAuth('me', {
    summary: 'Get current user profile',
    responseType: UserResponse,
    errors: [{ status: 404, description: 'User not found' }],
  })
  async getMe(@CurrentUserId() userId: string) {
    return this.getProfileUseCase.execute({ userId, includePrivate: true });
  }

  @GetAuth('me/stats', {
    summary: 'Get current user stats',
    responseType: UserStatsResponse,
  })
  async getMyStats(@CurrentUserId() userId: string) {
    return this.getUserStatsUseCase.execute({ userId });
  }

  @PatchAuth('me', {
    summary: 'Update profile',
    bodyType: UpdateProfileDTO,
    responseType: UserResponse,
    errors: [{ status: 404, description: 'User not found' }],
  })
  async updateProfile(@CurrentUserId() userId: string, @Body() body: UpdateProfileDTO) {
    return this.updateProfileUseCase.execute({ userId, ...body });
  }

  @PostAuth('me/avatar', {
    summary: 'Upload profile picture',
    description: 'Uploads an image to be used as profile avatar. Accepts JPEG, PNG, WebP, GIF up to 5MB.',
    responseType: UserResponse,
    httpCode: HttpStatus.OK,
  })
  @UseInterceptors(FileInterceptor('avatar', { storage: memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } }))
  async uploadAvatar(@CurrentUserId() userId: string, @UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Imagem é obrigatória');
    const mimeError = validateImageFile(file);
    if (mimeError) throw new BadRequestException(mimeError);

    const avatarUrl = saveUpload(file, 'avatar');
    const updateResult = await this.userRepository.update(userId, { avatarUrl });
    if (isLeft(updateResult)) return left(updateResult.value);
    return toUserResponse(updateResult.value, undefined, true);
  }

  @PostAuth('me/banner', {
    summary: 'Upload profile banner picture',
    description: 'Uploads an image to be used as profile banner. Accepts JPEG, PNG, WebP, GIF up to 8MB.',
    responseType: UserResponse,
    httpCode: HttpStatus.OK,
  })
  @UseInterceptors(FileInterceptor('banner', { storage: memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 } }))
  async uploadBanner(@CurrentUserId() userId: string, @UploadedFile() file?: Express.Multer.File) {
    if (!file) throw new BadRequestException('Imagem é obrigatória');
    const mimeError = validateImageFile(file, 8 * 1024 * 1024);
    if (mimeError) throw new BadRequestException(mimeError);

    const bannerUrl = saveUpload(file, 'banner');
    const updateResult = await this.userRepository.update(userId, { bannerUrl });
    if (isLeft(updateResult)) return left(updateResult.value);
    return toUserResponse(updateResult.value, undefined, true);
  }

  @PostAuth('me/phone', {
    summary: 'Register phone number for verification',
    bodyType: RegisterPhoneDTO,
    throttle: { short: { limit: 3, ttl: 60000 }, medium: { limit: 5, ttl: 60000 } },
    httpCode: HttpStatus.OK,
  })
  async registerPhone(@CurrentUserId() userId: string, @Body() body: RegisterPhoneDTO) {
    return this.registerPhoneUseCase.execute({ userId, phone: body.phone });
  }

  @PostAuth('me/phone/verify', {
    summary: 'Verify phone number using code',
    bodyType: VerifyPhoneDTO,
    throttle: { short: { limit: 5, ttl: 60000 }, medium: { limit: 10, ttl: 60000 } },
    httpCode: HttpStatus.OK,
  })
  async verifyPhone(@CurrentUserId() userId: string, @Body() body: VerifyPhoneDTO) {
    return this.verifyPhoneUseCase.execute({ userId, code: body.code });
  }

  @PatchAuth('me/fcm-token', {
    summary: 'Update FCM token',
    bodyType: UpdateFcmTokenDTO,
  })
  async updateFcmToken(@CurrentUserId() userId: string, @Body() body: UpdateFcmTokenDTO) {
    const result = await this.updateFcmTokenUseCase.execute({ userId, ...body });
    if (isLeft(result)) return result;
    return { success: true };
  }

  @GetAuth('blocked', {
    summary: 'Get blocked users',
    queries: [
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
      { name: 'offset', required: false, description: 'Pagination offset (default 0)' },
    ],
  })
  async getBlockedUsers(@CurrentUserId() userId: string, @Query() query: OffsetPaginationQueryDTO) {
    const parsedLimit = query.limit ?? 20;
    const parsedOffset = query.offset ?? 0;
    const result = await this.blockRepository.getBlockedUsers(userId, parsedLimit, parsedOffset);
    if (result.isLeft()) return result;

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

  @GetAuth('search', {
    summary: 'Search users',
    queries: [
      { name: 'q', required: false, description: 'Search query' },
      { name: 'offset', required: false, description: 'Pagination offset (default 0)' },
      { name: 'limit', required: false, description: 'Results per page (default 20)' },
    ],
  })
  async searchUsers(@CurrentUserId() userId: string, @Query() query: UserSearchQueryDTO) {
    const parsedLimit = query.limit ?? 20;
    const parsedOffset = query.offset ?? 0;
    const searchResult = await this.searchUsersUseCase.execute({
      query: query.q || '',
      limit: parsedLimit,
      offset: parsedOffset,
      viewerId: userId,
    });
    if (isLeft(searchResult)) return searchResult;
    const users = searchResult.value;

    return {
      users,
      hasMore: users.length === parsedLimit,
      nextOffset: users.length === parsedLimit ? parsedOffset + parsedLimit : null,
    };
  }

  @GetAuth('suggestions', {
    summary: 'Get user suggestions',
    queries: [{ name: 'limit', required: false, description: 'Number of suggestions (default 10)' }],
  })
  async getSuggestions(@CurrentUserId() userId: string, @Query() query: SuggestionsQueryDTO) {
    const suggestionsResult = await this.getSuggestionsUseCase.execute({
      userId,
      limit: query.limit ?? 10,
    });
    if (isLeft(suggestionsResult)) return suggestionsResult;
    return { users: suggestionsResult.value };
  }

  @GetPublic(':id', {
    summary: 'Get user by ID',
    params: [{ name: 'id', description: 'User UUID' }],
    responseType: UserResponse,
    errors: [{ status: 404, description: 'User not found' }],
  })
  async getUser(@Param('id', ParseUUIDPipe) id: string) {
    return this.getProfileUseCase.execute({ userId: id });
  }

  @PostAuth(':id/follow', {
    summary: 'Follow a user',
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: FollowResponse,
    errors: [
      { status: 404, description: 'User not found' },
      { status: 409, description: 'Already following' },
    ],
    httpCode: HttpStatus.OK,
  })
  async followUser(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUserId() userId: string) {
    return this.followUserUseCase.execute({ followerId: userId, followingId });
  }

  @PatchAuth(':id/unfollow', {
    summary: 'Unfollow a user',
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: FollowResponse,
    errors: [{ status: 404, description: 'Not following' }],
  })
  async unfollowUser(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUserId() userId: string) {
    return this.unfollowUserUseCase.execute({ followerId: userId, followingId });
  }

  @GetAuth('me/followers', 'Get current user followers')
  async getMyFollowers(@CurrentUserId() userId: string) {
    return this.fetchFollowers(userId, 20, 0);
  }

  @GetAuth('me/following', 'Get current user following')
  async getMyFollowing(@CurrentUserId() userId: string) {
    return this.fetchFollowing(userId, 20, 0);
  }

  @GetPublic(':id/followers', {
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

  @GetPublic(':id/following', {
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

  @GetAuth(':id/is-following', {
    summary: 'Check if following a user',
    params: [{ name: 'id', description: 'Target user UUID' }],
  })
  async isFollowing(@Param('id', ParseUUIDPipe) followingId: string, @CurrentUserId() userId: string) {
    const [isFollowingResult, followersCountResult, followingCountResult] = await Promise.all([
      this.followRepository.isFollowing(userId, followingId),
      this.followRepository.getFollowersCount(followingId),
      this.followRepository.getFollowingCount(followingId),
    ]);

    if (isFollowingResult.isLeft()) return isFollowingResult;
    if (followersCountResult.isLeft()) return followersCountResult;
    if (followingCountResult.isLeft()) return followingCountResult;

    return { isFollowing: isFollowingResult.value, followersCount: followersCountResult.value, followingCount: followingCountResult.value };
  }

  @PostAuth(':id/block', {
    summary: 'Block a user',
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: BlockResponse,
    errors: [
      { status: 404, description: 'User not found' },
      { status: 409, description: 'Already blocked' },
    ],
    httpCode: HttpStatus.OK,
  })
  async blockUser(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUserId() userId: string) {
    return this.blockUserUseCase.execute({ blockerId: userId, blockedId });
  }

  @PatchAuth(':id/unblock', {
    summary: 'Unblock a user',
    params: [{ name: 'id', description: 'Target user UUID' }],
    responseType: BlockResponse,
    errors: [{ status: 404, description: 'Not blocked' }],
  })
  async unblockUser(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUserId() userId: string) {
    return this.unblockUserUseCase.execute({ blockerId: userId, blockedId });
  }

  @GetAuth(':id/is-blocked', {
    summary: 'Check if a user is blocked',
    params: [{ name: 'id', description: 'Target user UUID' }],
  })
  async isBlocked(@Param('id', ParseUUIDPipe) blockedId: string, @CurrentUserId() userId: string) {
    const isBlockedResult = await this.blockRepository.isBlocked(userId, blockedId);
    if (isBlockedResult.isLeft()) return isBlockedResult;
    return { isBlocked: isBlockedResult.value };
  }

  private async ensureUserExists(id: string) {
    const targetResult = await this.userRepository.findById(id);
    if (isLeft(targetResult)) return left(targetResult.value);
    if (!targetResult.value) return left(new NotFoundError('Usuário'));
    return null;
  }

  private async fetchFollowers(userId: string, limit: number, offset: number) {
    const [followersResult, totalResult] = await Promise.all([
      this.followRepository.getFollowers(userId, limit, offset),
      this.followRepository.getFollowersCount(userId),
    ]);
    if (followersResult.isLeft()) return followersResult;
    if (totalResult.isLeft()) return totalResult;
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
    if (followingResult.isLeft()) return followingResult;
    if (totalResult.isLeft()) return totalResult;
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
