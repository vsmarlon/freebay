import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PrismaPostRepository {
  constructor(private prisma: PrismaService) {}

  async findById(id: string) {
    return this.prisma.post.findUnique({
      where: { id },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
        likes: { take: 3 },
        _count: { select: { likes: true, comments: true } },
      },
    });
  }

  async findFeed(params: { userId: string; limit: number; type?: 'explore' | 'following' }) {
    const { userId, limit, type = 'explore' } = params;

    let whereClause: Prisma.PostWhereInput = {};

    if (type === 'following' && userId) {
      const following = await this.prisma.follow.findMany({
        where: { followerId: userId },
        select: { followingId: true },
      });
      const followingIds = following.map(f => f.followingId);
      whereClause = { userId: { in: followingIds } };
    }

    return this.prisma.post.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
        likes: { take: 3 },
        _count: { select: { likes: true, comments: true } },
      },
    });
  }

  async findByUserId(userId: string, params: { limit: number; cursor?: string }) {
    return this.prisma.post.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: params.limit,
      ...(params.cursor ? { skip: 1, cursor: { id: params.cursor } } : {}),
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
        _count: { select: { likes: true, comments: true } },
      },
    });
  }

  async searchPosts(params: { query: string; filter: string; userId: string; limit: number; cursor?: string }) {
    return this.prisma.post.findMany({
      where: { content: { contains: params.query, mode: 'insensitive' } },
      orderBy: { createdAt: 'desc' },
      take: params.limit,
      ...(params.cursor ? { skip: 1, cursor: { id: params.cursor } } : {}),
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
        _count: { select: { likes: true, comments: true } },
      },
    });
  }

  async create(data: Prisma.PostCreateInput) {
    return this.prisma.post.create({ data });
  }

  async incrementSharesCount(postId: string) {
    return this.prisma.post.update({
      where: { id: postId },
      data: { sharesCount: { increment: 1 } },
    });
  }

  async incrementLikesCount(postId: string) {
    return this.prisma.post.update({
      where: { id: postId },
      data: { likesCount: { increment: 1 } },
    });
  }

  async decrementLikesCount(postId: string) {
    return this.prisma.post.update({
      where: { id: postId },
      data: { likesCount: { decrement: 1 } },
    });
  }

  async decrementSharesCount(postId: string) {
    return this.prisma.post.update({
      where: { id: postId },
      data: { sharesCount: { decrement: 1 } },
    });
  }

  async incrementCommentsCount(postId: string) {
    return this.prisma.post.update({
      where: { id: postId },
      data: { commentsCount: { increment: 1 } },
    });
  }
}
