import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { LikeRepository } from '../../domain/repositories/like.repository';

@Injectable()
export class PrismaLikeRepository extends BasePrismaRepository implements LikeRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findPostLike(userId: string, postId: string): RepositoryResponse<{ id: string } | null> {
    return this.safeRun(() => this.prisma.like.findUnique({
      where: { userId_postId: { userId, postId } },
      select: { id: true },
    }), 'Erro ao buscar like');
  }

  async createLike(data: Record<string, unknown>): RepositoryResponse<{ id: string }> {
    return this.safeRun(() => this.prisma.like.create({
      data: data as Prisma.LikeCreateInput,
      select: { id: true },
    }), 'Erro ao criar like');
  }

  async deletePostLikeByUser(userId: string, postId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.like.delete({ where: { userId_postId: { userId, postId } } });
    }, 'Erro ao remover like');
  }

  async findLikedByUserId(userId: string): RepositoryResponse<unknown[]> {
    return this.safeRun(async () => {
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
      return likes.map((l) => l.post);
    }, 'Erro ao buscar likes');
  }

  async findCommentLike(userId: string, commentId: string): RepositoryResponse<{ id: string } | null> {
    return this.safeRun(() => this.prisma.commentLike.findUnique({
      where: { userId_commentId: { userId, commentId } },
      select: { id: true },
    }), 'Erro ao buscar like do comentário');
  }

  async createCommentLike(data: Record<string, unknown>): RepositoryResponse<{ id: string }> {
    return this.safeRun(() => this.prisma.commentLike.create({
      data: data as Prisma.CommentLikeCreateInput,
      select: { id: true },
    }), 'Erro ao curtir comentário');
  }

  async deleteCommentLike(data: { userId: string; commentId: string }): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.commentLike.delete({
        where: { userId_commentId: { userId: data.userId, commentId: data.commentId } },
      });
    }, 'Erro ao remover like do comentário');
  }
}
