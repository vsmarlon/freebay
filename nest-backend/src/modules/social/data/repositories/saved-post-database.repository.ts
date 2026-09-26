import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { CursorPage } from '@/shared/core/pagination';
import { PostResponse, postIncludeForViewer, SavedPostsRepositoryQuery } from '../../types/social.types';
import { normalizePost } from './post-database.repository';

@Injectable()
export class PrismaSavedPostRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findByUserAndPost(userId: string, postId: string): RepositoryResponse<{ id: string } | null> {
    return repositoryResponse(() => this.prisma.savedPost.findUnique({
      where: { userId_postId: { userId, postId } },
      select: { id: true },
    }), 'Erro ao buscar post salvo');
  }

  async save(userId: string, postId: string): RepositoryResponse<{ id: string }> {
    return repositoryResponse(() => this.prisma.savedPost.create({
      data: { userId, postId },
      select: { id: true },
    }), 'Erro ao salvar post');
  }

  async unsave(userId: string, postId: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.savedPost.delete({ where: { userId_postId: { userId, postId } } });
    }, 'Erro ao remover post salvo');
  }

  async setSaved(userId: string, postId: string, active: boolean): RepositoryResponse<{ active: boolean }> {
    return repositoryResponse(() => this.prisma.$transaction(async (tx) => {
      const existing = await tx.savedPost.findUnique({ where: { userId_postId: { userId, postId } } });
      if (active && !existing) await tx.savedPost.create({ data: { userId, postId } });
      if (!active && existing) await tx.savedPost.delete({ where: { userId_postId: { userId, postId } } });
      return { active };
    }), 'Erro ao atualizar post salvo');
  }

  async findSaved(
    query: SavedPostsRepositoryQuery,
  ): RepositoryResponse<CursorPage<PostResponse>> {
    return repositoryResponse(async () => {
      const limit = query.limit ?? 20;
      const saved = await this.prisma.savedPost.findMany({
        where: {
          userId: query.userId,
          post: {
            deletedAt: null,
            user: {
              blocksGiven: { none: { blockedId: query.userId } },
              blocksReceived: { none: { blockerId: query.userId } },
            },
          },
          ...(query.cursor
            ? {
                OR: [
                  { createdAt: { lt: new Date(query.cursor.createdAt) } },
                  {
                    createdAt: new Date(query.cursor.createdAt),
                    id: { lt: query.cursor.savedPostId },
                  },
                ],
              }
            : {}),
        },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: limit + 1,
        include: { post: { include: postIncludeForViewer(query.userId) } },
      });
      const hasMore = saved.length > limit;
      const page = saved.slice(0, limit);
      const last = page[page.length - 1];
      return {
        items: page.map(({ post }) => normalizePost(post)),
        hasMore,
        nextCursor: hasMore && last
          ? Buffer.from(JSON.stringify({
              scope: 'saved-posts',
              userId: query.userId,
              createdAt: last.createdAt.toISOString(),
              savedPostId: last.id,
            }), 'utf8').toString('base64url')
          : null,
      };
    }, 'Erro ao buscar posts salvos');
  }
}
