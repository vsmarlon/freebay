import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ShareRepository, ShareWithPost } from '../../domain/repositories/share.repository';
import { POST_INCLUDE_FULL } from '../../types/social.types';

@Injectable()
export class PrismaShareRepository implements ShareRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findByUserAndPost(userId: string, postId: string): RepositoryResponse<{ id: string } | null> {
    try {
      const share = await this.prisma.share.findUnique({
        where: { userId_postId: { userId, postId } },
        select: { id: true },
      });
      return right(share);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar compartilhamento'));
    }
  }

  async create(data: Record<string, unknown>): RepositoryResponse<{ id: string }> {
    try {
      const share = await this.prisma.share.create({ data: data as Prisma.ShareCreateInput, select: { id: true } });
      return right(share);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao compartilhar'));
    }
  }

  async delete(userId: string, postId: string): RepositoryResponse<void> {
    try {
      await this.prisma.share.delete({ where: { userId_postId: { userId, postId } } });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao remover compartilhamento'));
    }
  }

  async findPostsRepostedByUser(userId: string, params: { limit?: number; cursor?: string }): RepositoryResponse<ShareWithPost[]> {
    try {
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
      return right(shares as ShareWithPost[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar reposts'));
    }
  }

  async exists(userId: string, postId: string): RepositoryResponse<boolean> {
    try {
      const count = await this.prisma.share.count({ where: { userId, postId } });
      return right(count > 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao verificar compartilhamento'));
    }
  }
}
