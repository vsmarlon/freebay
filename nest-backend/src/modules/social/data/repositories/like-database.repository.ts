import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { MutationState } from '../../types/social.types';
import { postVisibilityWhere } from './post-query-helpers';

@Injectable()
export class PrismaLikeRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findPostLike(userId: string, postId: string): RepositoryResponse<{ id: string } | null> {
    return repositoryResponse(() => this.prisma.like.findUnique({
      where: { userId_postId: { userId, postId } },
      select: { id: true },
    }), 'Erro ao buscar like');
  }

  async createLike(data: Prisma.LikeCreateInput): RepositoryResponse<{ id: string }> {
    return repositoryResponse(() => this.prisma.like.create({
      data,
      select: { id: true },
    }), 'Erro ao criar like');
  }

  async deletePostLikeByUser(userId: string, postId: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.like.delete({ where: { userId_postId: { userId, postId } } });
    }, 'Erro ao remover like');
  }

  async setPostLike(userId: string, postId: string, active: boolean): RepositoryResponse<MutationState> {
    return repositoryResponse(() => this.prisma.$transaction(async (tx) => {
      const existing = await tx.like.findUnique({ where: { userId_postId: { userId, postId } } });
      if (active && !existing) {
        await tx.like.create({ data: { userId, postId } });
        await tx.post.update({ where: { id: postId }, data: { likesCount: { increment: 1 } } });
      } else if (!active && existing) {
        await tx.like.delete({ where: { userId_postId: { userId, postId } } });
        await tx.post.updateMany({ where: { id: postId, likesCount: { gt: 0 } }, data: { likesCount: { decrement: 1 } } });
      }
      const post = await tx.post.findUnique({ where: { id: postId }, select: { likesCount: true } });
      return { active: active ? true : false, count: post?.likesCount ?? 0 };
    }), 'Erro ao atualizar like');
  }

  async findLikedByUserId(userId: string): RepositoryResponse<unknown[]> {
    return repositoryResponse(async () => {
      const likes = await this.prisma.like.findMany({
        where: { userId, post: { deletedAt: null, AND: [postVisibilityWhere(userId)] } },
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
    return repositoryResponse(() => this.prisma.commentLike.findUnique({
      where: { userId_commentId: { userId, commentId } },
      select: { id: true },
    }), 'Erro ao buscar like do comentário');
  }

  async createCommentLike(data: Prisma.CommentLikeCreateInput): RepositoryResponse<{ id: string }> {
    return repositoryResponse(() => this.prisma.commentLike.create({
      data,
      select: { id: true },
    }), 'Erro ao curtir comentário');
  }

  async deleteCommentLike(data: { userId: string; commentId: string }): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.commentLike.delete({
        where: { userId_commentId: { userId: data.userId, commentId: data.commentId } },
      });
    }, 'Erro ao remover like do comentário');
  }
}
