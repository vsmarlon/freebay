import { right, left } from '@/shared/core/either';
import { NotFoundError } from '@/shared/core/errors';
import { Test } from '@nestjs/testing';
import { FollowRepository } from '../domain/repositories/follow.repository';
import { UserLookupRepository } from '../domain/repositories/user-lookup.repository';
import { ListFollowersUseCase } from './list-followers.usecase';

describe('ListFollowersUseCase', () => {
  const followRepository = {
    isFollowing: jest.fn(),
    follow: jest.fn(),
    unfollow: jest.fn(),
    getFollowers: jest.fn(),
    getFollowing: jest.fn(),
    getFollowersCount: jest.fn(),
    getFollowingCount: jest.fn(),
  };
  const userRepository = { findById: jest.fn() };
  let sut: ListFollowersUseCase;

  beforeEach(() => {
    jest.clearAllMocks();
    followRepository.getFollowers.mockResolvedValue(right([]));
    followRepository.getFollowersCount.mockResolvedValue(right(0));
    userRepository.findById.mockResolvedValue(right({ id: 'user-1' }));
  });

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      providers: [
        ListFollowersUseCase,
        { provide: FollowRepository, useValue: followRepository },
        { provide: UserLookupRepository, useValue: userRepository },
      ],
    }).compile();
    sut = module.get(ListFollowersUseCase);
  });

  it('preserves pagination and returns mapped followers', async () => {
    followRepository.getFollowers.mockResolvedValue(right([{
      id: 'user-2',
      displayName: 'Follower',
      username: 'follower',
      avatarUrl: null,
      isVerified: false,
      reputationScore: 10,
    }]));
    followRepository.getFollowersCount.mockResolvedValue(right(1));

    const result = await sut.execute({ userId: 'user-1', limit: 5, offset: 10, verifyUser: true });

    expect(result).toEqual(right({
      users: [{
        id: 'user-2', displayName: 'Follower', username: 'follower', avatarUrl: null,
        isVerified: false, reputationScore: 10,
      }],
      total: 1,
      limit: 5,
      offset: 10,
    }));
    expect(userRepository.findById).toHaveBeenCalledWith('user-1');
  });

  it('returns the profile error before querying followers', async () => {
    const error = new NotFoundError('User');
    userRepository.findById.mockResolvedValue(left(error));

    const result = await sut.execute({ userId: 'missing', limit: 20, offset: 0, verifyUser: true });

    expect(result).toEqual(left(error));
    expect(followRepository.getFollowers).not.toHaveBeenCalled();
  });
});
