import { RepositoryResponse } from '@/shared/core/either';
import { UserBrief } from '../../types/user.types';

export abstract class FollowRepository {
  abstract follow(followerId: string, followingId: string): RepositoryResponse<void>;
  abstract unfollow(followerId: string, followingId: string): RepositoryResponse<void>;
  abstract isFollowing(followerId: string, followingId: string): RepositoryResponse<boolean>;
  abstract getFollowers(userId: string, limit: number, offset: number): RepositoryResponse<UserBrief[]>;
  abstract getFollowing(userId: string, limit: number, offset: number): RepositoryResponse<UserBrief[]>;
  abstract getFollowersCount(userId: string): RepositoryResponse<number>;
  abstract getFollowingCount(userId: string): RepositoryResponse<number>;
}
