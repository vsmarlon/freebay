import { Test, TestingModule } from '@nestjs/testing';
import { GetProfileUseCase, GetUserStatsUseCase, UpdateProfileUseCase, FollowUserUseCase, UnfollowUserUseCase, BlockUserUseCase, UnblockUserUseCase, SearchUsersUseCase, GetSuggestionsUseCase } from './user.usecase';
import { PrismaUserRepository } from '@/modules/auth/repositories/prisma-user.repository';
import { FollowRepository } from '../repositories/follow.repository';
import { BlockRepository } from '../repositories/block.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotFoundError, BadRequestError } from '@/shared/core/errors';

jest.mock('@/modules/auth/repositories/prisma-user.repository');
jest.mock('../repositories/follow.repository');
jest.mock('../repositories/block.repository');
jest.mock('@/shared/infra/prisma/prisma.service');

const mockUserRepository = {
  findById: jest.fn(),
  update: jest.fn(),
  searchUsers: jest.fn(),
  getSuggestions: jest.fn(),
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

const mockPrisma = {
  user: {
    update: jest.fn(),
  },
  order: {
    count: jest.fn(),
  },
};

describe('Users UseCases', () => {
  let getProfileUseCase: GetProfileUseCase;
  let getUserStatsUseCase: GetUserStatsUseCase;
  let updateProfileUseCase: UpdateProfileUseCase;
  let followUserUseCase: FollowUserUseCase;
  let unfollowUserUseCase: UnfollowUserUseCase;
  let blockUserUseCase: BlockUserUseCase;
  let unblockUserUseCase: UnblockUserUseCase;
  let searchUsersUseCase: SearchUsersUseCase;
  let getSuggestionsUseCase: GetSuggestionsUseCase;

  const mockUser = {
    id: 'user-123',
    displayName: 'Test User',
    avatarUrl: 'https://example.com/avatar.jpg',
    bio: 'Test bio',
    city: 'São Paulo',
    state: 'SP',
    isVerified: false,
    reputationScore: 4.5,
    totalReviews: 10,
    createdAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetProfileUseCase,
        GetUserStatsUseCase,
        UpdateProfileUseCase,
        FollowUserUseCase,
        UnfollowUserUseCase,
        BlockUserUseCase,
        UnblockUserUseCase,
        SearchUsersUseCase,
        GetSuggestionsUseCase,
        { provide: PrismaUserRepository, useValue: mockUserRepository },
        { provide: FollowRepository, useValue: mockFollowRepository },
        { provide: BlockRepository, useValue: mockBlockRepository },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    getProfileUseCase = module.get<GetProfileUseCase>(GetProfileUseCase);
    getUserStatsUseCase = module.get<GetUserStatsUseCase>(GetUserStatsUseCase);
    updateProfileUseCase = module.get<UpdateProfileUseCase>(UpdateProfileUseCase);
    followUserUseCase = module.get<FollowUserUseCase>(FollowUserUseCase);
    unfollowUserUseCase = module.get<UnfollowUserUseCase>(UnfollowUserUseCase);
    blockUserUseCase = module.get<BlockUserUseCase>(BlockUserUseCase);
    unblockUserUseCase = module.get<UnblockUserUseCase>(UnblockUserUseCase);
    searchUsersUseCase = module.get<SearchUsersUseCase>(SearchUsersUseCase);
    getSuggestionsUseCase = module.get<GetSuggestionsUseCase>(GetSuggestionsUseCase);

    jest.clearAllMocks();
  });

  describe('GetProfileUseCase', () => {
    it('should return user profile when found', async () => {
      mockUserRepository.findById.mockResolvedValue(mockUser);

      const result = await getProfileUseCase.execute({ userId: 'user-123' });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.id).toBe('user-123');
        expect(result.value.displayName).toBe('Test User');
      }
    });

    it('should return NotFoundError when user not found', async () => {
      mockUserRepository.findById.mockResolvedValue(null);

      const result = await getProfileUseCase.execute({ userId: 'nonexistent' });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(NotFoundError);
      }
    });
  });

  describe('GetUserStatsUseCase', () => {
    it('should return user stats', async () => {
      mockPrisma.order.count
        .mockResolvedValueOnce(5)
        .mockResolvedValueOnce(3);
      mockFollowRepository.getFollowersCount.mockResolvedValue(100);
      mockFollowRepository.getFollowingCount.mockResolvedValue(50);

      const result = await getUserStatsUseCase.execute({ userId: 'user-123' });

      expect(result.salesCount).toBe(5);
      expect(result.purchasesCount).toBe(3);
      expect(result.followersCount).toBe(100);
      expect(result.followingCount).toBe(50);
    });
  });

  describe('UpdateProfileUseCase', () => {
    it('should update and return user profile', async () => {
      const updatedUser = { ...mockUser, displayName: 'Updated Name' };
      mockUserRepository.update.mockResolvedValue(updatedUser);

      const result = await updateProfileUseCase.execute({ userId: 'user-123', displayName: 'Updated Name' });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.displayName).toBe('Updated Name');
      }
    });

    it('should return NotFoundError when user not found', async () => {
      mockUserRepository.update.mockResolvedValue(null);

      const result = await updateProfileUseCase.execute({ userId: 'nonexistent', displayName: 'New Name' });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(NotFoundError);
      }
    });
  });

  describe('FollowUserUseCase', () => {
    it('should follow user successfully', async () => {
      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockFollowRepository.follow.mockResolvedValue(undefined);
      mockFollowRepository.getFollowersCount.mockResolvedValue(101);
      mockFollowRepository.getFollowingCount.mockResolvedValue(51);

      const result = await followUserUseCase.execute({
        followerId: 'follower-123',
        followingId: 'following-123',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.following).toBe(true);
        expect(result.value.followersCount).toBe(101);
      }
    });

    it('should return BadRequestError when trying to follow self', async () => {
      const result = await followUserUseCase.execute({
        followerId: 'same-user',
        followingId: 'same-user',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(BadRequestError);
      }
    });

    it('should return NotFoundError when target user not found', async () => {
      mockUserRepository.findById.mockResolvedValue(null);

      const result = await followUserUseCase.execute({
        followerId: 'follower-123',
        followingId: 'nonexistent',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(NotFoundError);
      }
    });

    it('should return BadRequestError when already following', async () => {
      mockUserRepository.findById.mockResolvedValue(mockUser);
      const error = new Error('Unique constraint failed');
      (error as any).code = 'P2002';
      mockFollowRepository.follow.mockRejectedValue(error);

      const result = await followUserUseCase.execute({
        followerId: 'follower-123',
        followingId: 'following-123',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(BadRequestError);
      }
    });
  });

  describe('UnfollowUserUseCase', () => {
    it('should unfollow user successfully', async () => {
      mockFollowRepository.unfollow.mockResolvedValue(undefined);
      mockFollowRepository.getFollowersCount.mockResolvedValue(99);
      mockFollowRepository.getFollowingCount.mockResolvedValue(49);

      const result = await unfollowUserUseCase.execute({
        followerId: 'follower-123',
        followingId: 'following-123',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.following).toBe(false);
      }
    });

    it('should return BadRequestError when not following', async () => {
      const error = new Error('Record not found');
      (error as any).code = 'P2025';
      mockFollowRepository.unfollow.mockRejectedValue(error);

      const result = await unfollowUserUseCase.execute({
        followerId: 'follower-123',
        followingId: 'following-123',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(BadRequestError);
      }
    });
  });

  describe('BlockUserUseCase', () => {
    it('should block user successfully', async () => {
      mockUserRepository.findById.mockResolvedValue(mockUser);
      mockBlockRepository.block.mockResolvedValue(undefined);

      const result = await blockUserUseCase.execute({
        blockerId: 'blocker-123',
        blockedId: 'blocked-123',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.blocked).toBe(true);
      }
    });

    it('should return BadRequestError when trying to block self', async () => {
      const result = await blockUserUseCase.execute({
        blockerId: 'same-user',
        blockedId: 'same-user',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(BadRequestError);
      }
    });

    it('should return NotFoundError when target user not found', async () => {
      mockUserRepository.findById.mockResolvedValue(null);

      const result = await blockUserUseCase.execute({
        blockerId: 'blocker-123',
        blockedId: 'nonexistent',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(NotFoundError);
      }
    });
  });

  describe('UnblockUserUseCase', () => {
    it('should unblock user successfully', async () => {
      mockBlockRepository.unblock.mockResolvedValue(undefined);

      const result = await unblockUserUseCase.execute({
        blockerId: 'blocker-123',
        blockedId: 'blocked-123',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.blocked).toBe(false);
      }
    });

    it('should return BadRequestError when user not blocked', async () => {
      const error = new Error('Record not found');
      (error as any).code = 'P2025';
      mockBlockRepository.unblock.mockRejectedValue(error);

      const result = await unblockUserUseCase.execute({
        blockerId: 'blocker-123',
        blockedId: 'blocked-123',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(BadRequestError);
      }
    });
  });

  describe('SearchUsersUseCase', () => {
    it('should return search results', async () => {
      const searchResults = [
        { id: 'user-1', displayName: 'John', avatarUrl: null, bio: null, isVerified: false, reputationScore: 0, totalReviews: 0, _count: { followers: 10, following: 5 } },
      ];
      mockUserRepository.searchUsers.mockResolvedValue(searchResults);

      const result = await searchUsersUseCase.execute({ query: 'John', limit: 20 });

      expect(result).toHaveLength(1);
      expect(result[0].displayName).toBe('John');
    });
  });

  describe('GetSuggestionsUseCase', () => {
    it('should return suggestion results', async () => {
      const suggestions = [
        { id: 'user-2', displayName: 'Jane', avatarUrl: null, bio: null, isVerified: true, reputationScore: 4.8, totalReviews: 15, followersCount: 100, followingCount: 50, mutualCount: 5 },
      ];
      mockUserRepository.getSuggestions.mockResolvedValue(suggestions);

      const result = await getSuggestionsUseCase.execute({ userId: 'user-123', limit: 10 });

      expect(result).toHaveLength(1);
      expect(result[0].displayName).toBe('Jane');
      expect(result[0].mutualCount).toBe(5);
    });
  });
});
