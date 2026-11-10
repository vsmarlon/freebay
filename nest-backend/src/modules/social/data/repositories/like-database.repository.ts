import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { MutationState, PostResponse, postIncludeForViewer } from '../../types/social.types';
import { normalizePostsForViewer, postVisibilityWhere } from './post-query-helpers';

@Injectable()
export class LikeDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async setPostLike(userId: string, postId: string, active: boolean): RepositoryResponse<MutationState> {
    return repositoryResponse(async () => {
      try {
        return await this.applyPostLike(userId, postId, active);
      } catch (error) {
        // ponytail: unique-index race from a double click — one retry converges the
        // loser to the idempotent no-op path instead of surfacing a 500.
        if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
          return await this.applyPostLike(userId, postId, active);
        }
        throw error;
      }
    }, 'Erro ao atualizar like');
  }

  private async applyPostLike(userId: string, postId: string, active: boolean): Promise<MutationState> {
    return this.prisma.$transaction(async (tx) => {
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
    });
  }

  async findLikedByUserId(userId: string): RepositoryResponse<PostResponse[]> {
    return repositoryResponse(async () => {
      const likes = await this.prisma.like.findMany({
        where: { userId, post: { deletedAt: null, AND: [postVisibilityWhere(userId)] } },
        include: {
          post: { include: postIncludeForViewer(userId) },
        },
        orderBy: { createdAt: 'desc' },
      });
      return normalizePostsForViewer(likes.map((like) => like.post), userId, this.prisma);
    }, 'Erro ao buscar likes');
  }
}
