import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { POST_INCLUDE_FULL, ShareWithPost } from '../../types/social.types';

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

  async findPostsRepostedByUser(userId: string, params: { limit?: number; cursor?: string }): RepositoryResponse<ShareWithPost[]> {
    return this.safeRun(async () => {
      const shares = await this.prisma.share.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: params.limit ?? 20,
        ...(params.cursor ? { skip: 1, cursor: { id: params.cursor } } : {}),
        include: {
          post: { include: POST_INCLUDE_FULL },
          user: { select: { id: true, displayName: true, avatarUrl: true } },
        },
      });
      return shares as ShareWithPost[];
    }, 'Erro ao buscar reposts');
  }

  async exists(userId: string, postId: string): RepositoryResponse<boolean> {
    return this.safeRun(async () => {
      const count = await this.prisma.share.count({ where: { userId, postId } });
      return count > 0;
    }, 'Erro ao verificar compartilhamento');
  }
}
