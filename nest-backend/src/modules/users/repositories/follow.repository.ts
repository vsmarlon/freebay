import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class FollowRepository {
  constructor(private prisma: PrismaService) {}

  async follow(followerId: string, followingId: string) {
    return this.prisma.follow.create({
      data: { followerId, followingId },
    });
  }

  async unfollow(followerId: string, followingId: string) {
    return this.prisma.follow.delete({
      where: {
        followerId_followingId: { followerId, followingId },
      },
    });
  }

  async isFollowing(followerId: string, followingId: string): Promise<boolean> {
    const follow = await this.prisma.follow.findUnique({
      where: { followerId_followingId: { followerId, followingId } },
    });
    return !!follow;
  }

  async getFollowers(userId: string, limit: number, offset: number) {
    return this.prisma.user.findMany({
      where: { following: { some: { followingId: userId } } },
      take: limit,
      skip: offset,
      select: {
        id: true,
        displayName: true,
        avatarUrl: true,
        isVerified: true,
        reputationScore: true,
      },
    });
  }

  async getFollowing(userId: string, limit: number, offset: number) {
    return this.prisma.user.findMany({
      where: { followers: { some: { followerId: userId } } },
      take: limit,
      skip: offset,
      select: {
        id: true,
        displayName: true,
        avatarUrl: true,
        isVerified: true,
        reputationScore: true,
      },
    });
  }

  async getFollowersCount(userId: string): Promise<number> {
    return this.prisma.follow.count({ where: { followingId: userId } });
  }

  async getFollowingCount(userId: string): Promise<number> {
    return this.prisma.follow.count({ where: { followerId: userId } });
  }
}
