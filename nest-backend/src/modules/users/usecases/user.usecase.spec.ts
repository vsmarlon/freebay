import { Test, TestingModule } from '@nestjs/testing';
import {
  GetProfileUseCase,
  UpdateProfileUseCase,
  FollowUserUseCase,
  UnfollowUserUseCase,
  BlockUserUseCase,
  UnblockUserUseCase,
} from './index';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { FollowRepository } from '../domain/repositories/follow.repository';
import { BlockRepository } from '../domain/repositories/block.repository';
import { PrismaOrderRepository } from '@/modules/orders/data/repositories/order-database.repository';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { BadRequestError, NotFoundError } from '@/shared/core/errors';
import { left, right } from '@/shared/core/either';
import { expectLeft, expectRight, mockUser, rightCounts } from './user-test-fixtures';

const mockUserRepository = {
  findById: jest.fn(),
  findByUsername: jest.fn(),
  update: jest.fn(),
  searchUsers: jest.fn(),
  getSuggestions: jest.fn(),
  getProfileCounts: jest.fn(),
};

const mockFollowRepository = {
  getFollowersCount: jest.fn(),
  getFollowingCount: jest.fn(),
  follow: jest.fn(),
  unfollow: jest.fn(),
};

const mockBlockRepository = {
  block: jest.fn(),
  unblock: jest.fn(),
  isBlocked: jest.fn(),
};

const mockOrderRepository = {
  countBySellerId: jest.fn(),
  countByBuyerId: jest.fn(),
};

const mockNotificationService = {
  notifyNewFollower: jest.fn().mockResolvedValue(undefined),
};

const compileSubject = async (): Promise<TestingModule> => Test.createTestingModule({
  providers: [
    GetProfileUseCase,
    UpdateProfileUseCase,
    FollowUserUseCase,
    UnfollowUserUseCase,
    BlockUserUseCase,
    UnblockUserUseCase,
    { provide: UserDatabaseRepository, useValue: mockUserRepository },
    { provide: FollowRepository, useValue: mockFollowRepository },
    { provide: BlockRepository, useValue: mockBlockRepository },
    { provide: PrismaOrderRepository, useValue: mockOrderRepository },
    { provide: NotificationService, useValue: mockNotificationService },
  ],
}).compile();

describe('Users UseCases', () => {
  let getProfileUseCase: GetProfileUseCase;
  let updateProfileUseCase: UpdateProfileUseCase;
  let followUserUseCase: FollowUserUseCase;
  let unfollowUserUseCase: UnfollowUserUseCase;
  let blockUserUseCase: BlockUserUseCase;
  let unblockUserUseCase: UnblockUserUseCase;

  beforeEach(async () => {
    const module = await compileSubject();
    getProfileUseCase = module.get(GetProfileUseCase);
    updateProfileUseCase = module.get(UpdateProfileUseCase);
    followUserUseCase = module.get(FollowUserUseCase);
    unfollowUserUseCase = module.get(UnfollowUserUseCase);
    blockUserUseCase = module.get(BlockUserUseCase);
    unblockUserUseCase = module.get(UnblockUserUseCase);

    jest.clearAllMocks();
    mockUserRepository.getProfileCounts.mockResolvedValue(rightCounts());
    mockUserRepository.findByUsername.mockResolvedValue(right(null));
  });

  describe('GetProfileUseCase', () => {
    it('returns NotFoundError when user not found', async () => {
      mockUserRepository.findById.mockResolvedValue(right(null));

      const result = await getProfileUseCase.execute({ userId: 'nonexistent' });

      expect(expectLeft(result)).toBeInstanceOf(NotFoundError);
    });
  });

  describe('UpdateProfileUseCase', () => {
    it('returns NotFoundError when user not found', async () => {
      mockUserRepository.update.mockResolvedValue(right(null));

      const result = await updateProfileUseCase.execute({ userId: 'nonexistent', displayName: 'New Name' });

      expect(expectLeft(result)).toBeInstanceOf(NotFoundError);
    });
  });

  describe('FollowUserUseCase', () => {
    it('follows user successfully', async () => {
      mockUserRepository.findById.mockResolvedValue(right(mockUser));
      mockFollowRepository.follow.mockResolvedValue(right(undefined));
      mockFollowRepository.getFollowersCount.mockResolvedValue(right(101));
      mockFollowRepository.getFollowingCount.mockResolvedValue(right(51));

      const result = await followUserUseCase.execute({ followerId: 'follower-123', followingId: 'following-123' });
      const follow = expectRight(result);

      expect(follow.following).toBe(true);
      expect(follow.followersCount).toBe(101);
    });

    it('returns BadRequestError when trying to follow self', async () => {
      const result = await followUserUseCase.execute({ followerId: 'same-user', followingId: 'same-user' });

      expect(expectLeft(result)).toBeInstanceOf(BadRequestError);
    });

    it('returns NotFoundError when target user not found', async () => {
      mockUserRepository.findById.mockResolvedValue(right(null));

      const result = await followUserUseCase.execute({ followerId: 'follower-123', followingId: 'nonexistent' });

      expect(expectLeft(result)).toBeInstanceOf(NotFoundError);
    });

    it('returns BadRequestError when already following', async () => {
      mockUserRepository.findById.mockResolvedValue(right(mockUser));
      mockFollowRepository.follow.mockResolvedValue(left(new BadRequestError('Already following')));

      const result = await followUserUseCase.execute({ followerId: 'follower-123', followingId: 'following-123' });

      expect(expectLeft(result)).toBeInstanceOf(BadRequestError);
    });

  });

  describe('UnfollowUserUseCase', () => {
    it('unfollows user successfully', async () => {
      mockFollowRepository.unfollow.mockResolvedValue(right(undefined));
      mockFollowRepository.getFollowersCount.mockResolvedValue(right(99));
      mockFollowRepository.getFollowingCount.mockResolvedValue(right(49));

      const result = await unfollowUserUseCase.execute({ followerId: 'follower-123', followingId: 'following-123' });
      const unfollow = expectRight(result);

      expect(unfollow.following).toBe(false);
    });

    it('returns BadRequestError when not following', async () => {
      mockFollowRepository.unfollow.mockResolvedValue(left(new BadRequestError('Not following')));

      const result = await unfollowUserUseCase.execute({ followerId: 'follower-123', followingId: 'following-123' });

      expect(expectLeft(result)).toBeInstanceOf(BadRequestError);
    });
  });

  describe('BlockUserUseCase', () => {
    it('blocks user successfully', async () => {
      mockUserRepository.findById.mockResolvedValue(right(mockUser));
      mockBlockRepository.block.mockResolvedValue(right(undefined));

      const result = await blockUserUseCase.execute({ blockerId: 'blocker-123', blockedId: 'blocked-123' });
      const block = expectRight(result);

      expect(block.blocked).toBe(true);
    });

    it('returns BadRequestError when trying to block self', async () => {
      const result = await blockUserUseCase.execute({ blockerId: 'same-user', blockedId: 'same-user' });

      expect(expectLeft(result)).toBeInstanceOf(BadRequestError);
    });

    it('returns NotFoundError when target user not found', async () => {
      mockUserRepository.findById.mockResolvedValue(right(null));

      const result = await blockUserUseCase.execute({ blockerId: 'blocker-123', blockedId: 'nonexistent' });

      expect(expectLeft(result)).toBeInstanceOf(NotFoundError);
    });
  });

  describe('UnblockUserUseCase', () => {
    it('unblocks user successfully', async () => {
      mockBlockRepository.unblock.mockResolvedValue(right(undefined));

      const result = await unblockUserUseCase.execute({ blockerId: 'blocker-123', blockedId: 'blocked-123' });
      const unblock = expectRight(result);

      expect(unblock.blocked).toBe(false);
    });

    it('returns BadRequestError when user not blocked', async () => {
      mockBlockRepository.unblock.mockResolvedValue(left(new BadRequestError('Not blocked')));

      const result = await unblockUserUseCase.execute({ blockerId: 'blocker-123', blockedId: 'blocked-123' });

      expect(expectLeft(result)).toBeInstanceOf(BadRequestError);
    });
  });

});
