import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { postIncludeForViewer, ShareWithPost, MutationState } from '../../types/social.types';
import { normalizePost } from './post-database.repository';

@Injectable()
export class PrismaShareRepository extends BasePrismaRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findByUserAndPost(userId: string, postId: string): RepositoryResponse<{ id: string } | null> {
    return this.safeRun(() => this.prisma.share.findUnique({
      where: { userId_postId: { userId, postId } },
      select: { id: true },
    }), 'Erro ao buscar compartilhamento');
  }

  async create(data: Record<string, unknown>): RepositoryResponse<{ id: string }> {
    return this.safeRun(() => this.prisma.share.create({
      data: data as Prisma.ShareCreateInput,
      select: { id: true },
    }), 'Erro ao compartilhar');
  }

  async delete(userId: string, postId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.share.delete({ where: { userId_postId: { userId, postId } } });
    }, 'Erro ao remover compartilhamento');
  }

  async setPostShare(userId: string, postId: string, active: boolean): RepositoryResponse<MutationState> {
    return this.safeRun(() => this.prisma.$transaction(async (tx) => {
      const existing = await tx.share.findUnique({ where: { userId_postId: { userId, postId } } });
      if (active && !existing) {
        await tx.share.create({ data: { userId, postId } });
        await tx.post.update({ where: { id: postId }, data: { sharesCount: { increment: 1 } } });
      } else if (!active && existing) {
        await tx.share.delete({ where: { userId_postId: { userId, postId } } });
        await tx.post.updateMany({ where: { id: postId, sharesCount: { gt: 0 } }, data: { sharesCount: { decrement: 1 } } });
      }
      const post = await tx.post.findUnique({ where: { id: postId }, select: { sharesCount: true } });
      return { active, count: post?.sharesCount ?? 0 };
    }), 'Erro ao atualizar compartilhamento');
  }

  async findPostsRepostedByUser(userId: string, params: { viewerId?: string; limit?: number; cursor?: string }): RepositoryResponse<ShareWithPost[]> {
    return this.safeRun(async () => {
      const shares = await this.prisma.share.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: params.limit ?? 20,
        ...(params.cursor ? { skip: 1, cursor: { id: params.cursor } } : {}),
        include: {
          post: { include: postIncludeForViewer(params.viewerId) },
          user: { select: { id: true, displayName: true, avatarUrl: true } },
        },
      });
      return shares.map((share) => ({
        ...share,
        post: normalizePost(share.post),
      }));
    }, 'Erro ao buscar reposts');
  }

  async exists(userId: string, postId: string): RepositoryResponse<boolean> {
    return this.safeRun(async () => {
      const count = await this.prisma.share.count({ where: { userId, postId } });
      return count > 0;
    }, 'Erro ao verificar compartilhamento');
  }
}
