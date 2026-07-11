import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PostRepository, FeedQuery, UserPostsQuery, SearchPostsQuery } from '../../domain/repositories/post.repository';
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

  async findFeed(query: FeedQuery): RepositoryResponse<PostPayload[]> {
    try {
      const where: Prisma.PostWhereInput = {};
      if (query.type === 'following' && query.userId) {
        const follows = await this.prisma.follow.findMany({
          where: { followerId: query.userId },
          select: { followingId: true },
        });
        where.userId = { in: follows.map((f) => f.followingId) };
      }

      const limit = query.limit ?? 20;
      const posts = await this.prisma.post.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: limit * 3,
        include: POST_INCLUDE,
      });

      let ranked: typeof posts;

      if (query.type === 'following') {
        ranked = posts.slice(0, limit);
      } else {
        const now = Date.now();
        ranked = posts
          .map((post) => {
            const ageHours = (now - new Date(post.createdAt).getTime()) / 3_600_000;
            const engagement = post.likesCount * 3 + post.commentsCount * 5 + post.sharesCount * 4;
            const score = (engagement + 1) * Math.exp(-ageHours / 48);
            return { post, score };
          })
          .sort((a, b) => b.score - a.score)
          .slice(0, limit)
          .map(({ post }) => post);
      }

      return right(ranked as PostPayload[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar feed'));
    }
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
}
