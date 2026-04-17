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
}

@Injectable()
export class PrismaCommentRepository {
  constructor(private prisma: PrismaService) {}

  async findByPostId(postId: string, params: { limit: number; cursor?: string }) {
    return this.prisma.comment.findMany({
      where: { postId, parentId: null },
      orderBy: { createdAt: 'asc' },
      take: params.limit,
      ...(params.cursor ? { skip: 1, cursor: { id: params.cursor } } : {}),
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
        replies: {
          include: {
            user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
            _count: true,
          },
          orderBy: { createdAt: 'asc' as const },
        },
        _count: true,
      },
    });
  }

  async create(data: Prisma.CommentCreateInput) {
    return this.prisma.comment.create({ data });
  }
}

@Injectable()
export class PrismaLikeRepository {
  constructor(private prisma: PrismaService) {}

  async findByPostId(postId: string) {
    return this.prisma.like.findMany({ where: { postId } });
  }

  async findByCommentId(commentId: string) {
    return this.prisma.commentLike.findMany({ where: { commentId } });
  }

  async createLike(data: Prisma.LikeCreateInput) {
    return this.prisma.like.create({ data });
  }

  async createCommentLike(data: Prisma.CommentLikeCreateInput) {
    return this.prisma.commentLike.create({ data });
  }

  async deleteLike(data: Prisma.LikeWhereUniqueInput) {
    return this.prisma.like.delete({ where: data });
  }

  async deleteCommentLike(data: Prisma.CommentLikeWhereUniqueInput) {
    return this.prisma.commentLike.delete({ where: data });
  }

  async findLikedByUserId(userId: string) {
    return this.prisma.like.findMany({
      where: { userId },
      include: {
        post: {
          include: {
            user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
            _count: { select: { likes: true, comments: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}

@Injectable()
export class PrismaShareRepository {
  constructor(private prisma: PrismaService) {}

  async findByUserAndPost(userId: string, postId: string) {
    return this.prisma.share.findUnique({
      where: { userId_postId: { userId, postId } },
    });
  }

  async create(data: Prisma.ShareCreateInput) {
    return this.prisma.share.create({ data });
  }
}

@Injectable()
export class PrismaSavedPostRepository {
  constructor(private prisma: PrismaService) {}

  async findByUserAndPost(userId: string, postId: string) {
    return this.prisma.savedPost.findUnique({
      where: { userId_postId: { userId, postId } },
    });
  }

  async save(userId: string, postId: string) {
    return this.prisma.savedPost.create({
      data: {
        user: { connect: { id: userId } },
        post: { connect: { id: postId } },
      },
    });
  }

  async unsave(userId: string, postId: string) {
    return this.prisma.savedPost.delete({
      where: { userId_postId: { userId, postId } },
    });
  }
}

@Injectable()
export class PrismaStoryRepository {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    return this.prisma.story.findMany({
      where: { createdAt: { gte: yesterday } },
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
    });
  }

  async findByUserId(userId: string) {
    return this.prisma.story.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string) {
    return this.prisma.story.findUnique({ where: { id } });
  }

  async create(data: Prisma.StoryCreateInput) {
    return this.prisma.story.create({ data });
  }

  async delete(id: string) {
    return this.prisma.story.delete({ where: { id } });
  }
}
