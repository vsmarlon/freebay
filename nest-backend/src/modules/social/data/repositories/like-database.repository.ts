import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { LikeRepository } from '../../domain/repositories/like.repository';

@Injectable()
export class PrismaLikeRepository implements LikeRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findPostLike(userId: string, postId: string): RepositoryResponse<{ id: string } | null> {
    try {
      const like = await this.prisma.like.findUnique({
        where: { userId_postId: { userId, postId } },
        select: { id: true },
      });
      return right(like);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar like'));
    }
  }

  async createLike(data: Record<string, unknown>): RepositoryResponse<{ id: string }> {
    try {
      const like = await this.prisma.like.create({ data: data as Prisma.LikeCreateInput, select: { id: true } });
      return right(like);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar like'));
    }
  }

  async deletePostLikeByUser(userId: string, postId: string): RepositoryResponse<void> {
    try {
      await this.prisma.like.delete({ where: { userId_postId: { userId, postId } } });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao remover like'));
    }
  }

  async findLikedByUserId(userId: string): RepositoryResponse<unknown[]> {
    try {
      const likes = await this.prisma.like.findMany({
        where: { userId },
        include: {
          post: {
            include: {
              user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
              _count: { select: { likes: true, comments: true, shares: true } },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });
      return right(likes.map((l) => l.post));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar likes'));
    }
  }

  async findCommentLike(userId: string, commentId: string): RepositoryResponse<{ id: string } | null> {
    try {
      const like = await this.prisma.commentLike.findUnique({
        where: { userId_commentId: { userId, commentId } },
        select: { id: true },
      });
      return right(like);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar like do comentário'));
    }
  }

  async createCommentLike(data: Record<string, unknown>): RepositoryResponse<{ id: string }> {
    try {
      const like = await this.prisma.commentLike.create({ data: data as Prisma.CommentLikeCreateInput, select: { id: true } });
      return right(like);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao curtir comentário'));
    }
  }

  async deleteCommentLike(data: { userId: string; commentId: string }): RepositoryResponse<void> {
    try {
      await this.prisma.commentLike.delete({
        where: { userId_commentId: { userId: data.userId, commentId: data.commentId } },
      });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao remover like do comentário'));
    }
  }
}
