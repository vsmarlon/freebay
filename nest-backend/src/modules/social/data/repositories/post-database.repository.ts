import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PostRepository, FeedQuery, FeedResult, UserPostsQuery, SearchPostsQuery } from '../../domain/repositories/post.repository';
import { PostPayload, POST_INCLUDE } from '../../types/social.types';

@Injectable()
export class PrismaPostRepository implements PostRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string): RepositoryResponse<PostPayload | null> {
    try {
      const post = await this.prisma.post.findUnique({
        where: { id },
        include: POST_INCLUDE,
      });
      return right(post as PostPayload | null);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar post'));
    }
  }

  async findFeed(query: FeedQuery): RepositoryResponse<FeedResult> {
    try {
      const limit = query.limit ?? 20;
      const where: Prisma.PostWhereInput = {};

      if (query.contentFilter === 'social') {
        where.type = 'REGULAR';
      } else if (query.contentFilter === 'selling') {
        where.type = 'PRODUCT';
      }

      if (query.userId) {
        where.AND = [
          { user: { blocksGiven: { none: { blockedId: query.userId } } } },
          { user: { blocksReceived: { none: { blockerId: query.userId } } } },
        ];
      }

      if (query.type === 'following') {
        return right(await this.findFollowingFeed(where, query));
      }
      return right(await this.findExploreFeed(where, query, limit));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar feed'));
    }
  }

  private async findFollowingFeed(
    where: Prisma.PostWhereInput,
    query: FeedQuery,
  ): Promise<FeedResult> {
    const limit = query.limit ?? 20;
    const followingWhere: Prisma.PostWhereInput = { ...where };

    if (query.userId) {
      const follows = await this.prisma.follow.findMany({
        where: { followerId: query.userId },
        select: { followingId: true },
      });
      followingWhere.userId = { in: follows.map((f) => f.followingId) };
    }

    const posts = await this.prisma.post.findMany({
      where: followingWhere,
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
      include: POST_INCLUDE,
    });

    const hasMore = posts.length > limit;
    const page = posts.slice(0, limit);

    return {
      posts: page as PostPayload[],
      hasMore,
      nextCursor: hasMore ? (page[page.length - 1]?.id ?? null) : null,
    };
  }

  private async findExploreFeed(
    where: Prisma.PostWhereInput,
    query: FeedQuery,
    limit: number,
  ): Promise<FeedResult> {
    const CANDIDATE_WINDOW = 300;
    const offset = query.offset ?? 0;

    let followingIds: string[] = [];
    if (query.userId) {
      const follows = await this.prisma.follow.findMany({
        where: { followerId: query.userId },
        select: { followingId: true },
      });
      followingIds = follows.map((f) => f.followingId);
    }

    const candidates = await this.prisma.post.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: CANDIDATE_WINDOW,
      include: POST_INCLUDE,
    });

    const now = Date.now();
    const scored = candidates
      .map((post) => {
        const ageHours = (now - new Date(post.createdAt).getTime()) / 3_600_000;
        const engagement = post.likesCount * 3 + post.commentsCount * 5 + post.sharesCount * 4;
        const affinityBoost = followingIds.includes(post.userId) ? 1.5 : 1;
        const score = (engagement + 1) * Math.exp(-ageHours / 48) * affinityBoost;
        return { post, score };
      })
      .sort((a, b) => b.score - a.score);

    const page = scored.slice(offset, offset + limit).map(({ post }) => post);
    const hasMore = offset + limit < scored.length;

    return {
      posts: page as PostPayload[],
      hasMore,
      nextOffset: hasMore ? offset + limit : null,
    };
  }

  async findByUserId(query: UserPostsQuery): RepositoryResponse<PostPayload[]> {
    try {
      const posts = await this.prisma.post.findMany({
        where: { userId: query.userId },
        orderBy: { createdAt: 'desc' },
        take: query.limit ?? 20,
        ...(query.cursor ? { skip: 1, cursor: { id: query.cursor } } : {}),
        include: POST_INCLUDE,
      });
      return right(posts as PostPayload[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar posts do usuário'));
    }
  }

  async searchPosts(query: SearchPostsQuery): RepositoryResponse<PostPayload[]> {
    try {
      const where: Prisma.PostWhereInput = {
        content: { contains: query.query, mode: 'insensitive' },
      };

      if (query.userId) {
        if (query.filter === 'following') {
          where.user = {
            followers: {
              some: {
                followerId: query.userId,
              },
            },
          };
        } else if (query.filter === 'followers') {
          where.user = {
            following: {
              some: {
                followingId: query.userId,
              },
            },
          };
        }
      }

      const posts = await this.prisma.post.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: query.limit ?? 20,
        ...(query.cursor ? { skip: 1, cursor: { id: query.cursor } } : {}),
        include: POST_INCLUDE,
      });
      return right(posts as PostPayload[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar posts'));
    }
  }

  async create(data: Record<string, unknown>): RepositoryResponse<PostPayload> {
    try {
      const post = await this.prisma.post.create({ data: data as Prisma.PostCreateInput, include: POST_INCLUDE });
      return right(post as PostPayload);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar post'));
    }
  }

  async update(id: string, data: Record<string, unknown>): RepositoryResponse<unknown> {
    try {
      return right(await this.prisma.post.update({ where: { id }, data: data as Prisma.PostUpdateInput }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao atualizar post'));
    }
  }

  async createMentions(postId: string, mentionedUserIds: string[]): RepositoryResponse<void> {
    try {
      await this.prisma.postMention.createMany({
        data: mentionedUserIds.map((mentionedUserId) => ({ postId, mentionedUserId })),
        skipDuplicates: true,
      });
      return right(undefined);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar menções'));
    }
  }
}
