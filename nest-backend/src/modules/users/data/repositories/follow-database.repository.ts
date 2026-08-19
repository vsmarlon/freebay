import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { BadRequestError, DatabaseError } from '@/shared/core/errors';
import { FollowRepository } from '../../domain/repositories/follow.repository';
import { UserBrief } from '../../types/user.types';

@Injectable()
export class PrismaFollowRepository extends BasePrismaRepository implements FollowRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async follow(followerId: string, followingId: string): RepositoryResponse<void> {
    try {
      await this.prisma.follow.create({ data: { followerId, followingId } });
      return right(undefined);
    } catch (error: any) {
      if (error?.code === 'P2002') return left(new BadRequestError('Already following'));
      return left(new DatabaseError('Failed to follow user'));
    }
  }

  async unfollow(followerId: string, followingId: string): RepositoryResponse<void> {
    try {
      await this.prisma.follow.delete({ where: { followerId_followingId: { followerId, followingId } } });
      return right(undefined);
    } catch (error: any) {
      if (error?.code === 'P2025') return left(new BadRequestError('Not following'));
      return left(new DatabaseError('Failed to unfollow user'));
    }
  }

  async isFollowing(followerId: string, followingId: string): RepositoryResponse<boolean> {
    return this.safeRun(async () => {
      const follow = await this.prisma.follow.findUnique({ where: { followerId_followingId: { followerId, followingId } } });
      return !!follow;
    }, 'Failed to check follow status');
  }

  async getFollowers(userId: string, limit: number, offset: number): RepositoryResponse<UserBrief[]> {
    return this.safeRun(() => this.prisma.user.findMany({
      where: { following: { some: { followingId: userId } } },
      take: limit,
      skip: offset,
      select: { id: true, displayName: true, avatarUrl: true, isVerified: true, reputationScore: true },
    }), 'Failed to get followers');
  }

  async getFollowing(userId: string, limit: number, offset: number): RepositoryResponse<UserBrief[]> {
    return this.safeRun(() => this.prisma.user.findMany({
      where: { followers: { some: { followerId: userId } } },
      take: limit,
      skip: offset,
      select: { id: true, displayName: true, avatarUrl: true, isVerified: true, reputationScore: true },
    }), 'Failed to get following');
  }

  async getFollowersCount(userId: string): RepositoryResponse<number> {
    return this.safeRun(() => this.prisma.follow.count({ where: { followingId: userId } }), 'Failed to get followers count');
  }

  async getFollowingCount(userId: string): RepositoryResponse<number> {
    return this.safeRun(() => this.prisma.follow.count({ where: { followerId: userId } }), 'Failed to get following count');
  }
}
