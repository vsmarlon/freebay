import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma, User } from '@prisma/client';

@Injectable()
export class PrismaUserRepository {
  constructor(private prisma: PrismaService) {}

  async findById(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { email } });
  }

  async create(data: Prisma.UserCreateInput): Promise<User> {
    return this.prisma.user.create({ data });
  }

  async update(id: string, data: Prisma.UserUpdateInput): Promise<User> {
    return this.prisma.user.update({
      where: { id },
      data,
    });
  }

  async searchUsers(query: string, limit: number, cursor?: string) {
    return this.prisma.user.findMany({
      where: {
        displayName: { contains: query, mode: 'insensitive' },
      },
      take: limit,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      select: {
        id: true,
        displayName: true,
        avatarUrl: true,
        bio: true,
        isVerified: true,
        reputationScore: true,
        totalReviews: true,
        _count: {
          select: { followers: true, following: true },
        },
      },
    });
  }

  async getSuggestions(userId: string, limit: number) {
    const following = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });

    const followingIds = following.map((f) => f.followingId);

    const suggestions = await this.prisma.user.findMany({
      where: {
        id: { not: userId },
        following: {
          some: {
            followerId: { in: followingIds },
          },
        },
        NOT: {
          followers: {
            some: { followerId: userId },
          },
        },
      },
      take: limit,
      select: {
        id: true,
        displayName: true,
        avatarUrl: true,
        bio: true,
        isVerified: true,
        reputationScore: true,
        totalReviews: true,
        _count: {
          select: { followers: true, following: true },
        },
      },
    });

    return suggestions.map((u) => ({
      ...u,
      followersCount: u._count.followers,
      followingCount: u._count.following,
      mutualCount: 0,
    }));
  }
}
