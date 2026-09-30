import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { RepositoryResponse } from '@/shared/core/either';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { storyAudienceWhere } from './story-database.repository';

const highlightPayload = Prisma.validator<Prisma.StoryHighlightDefaultArgs>()({
  include: {
    user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
    stories: {
      orderBy: { position: 'asc' },
      include: { story: true },
    },
  },
});

export type HighlightPayload = Prisma.StoryHighlightGetPayload<typeof highlightPayload>;

@Injectable()
export class StoryHighlightDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {}

  findOwnerArchive(userId: string) {
    return repositoryResponse(() => this.prisma.story.findMany({
      where: { userId, deletedAt: null },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } } },
      orderBy: { createdAt: 'desc' },
    }), 'Erro ao buscar arquivo de stories');
  }

  findOwnedStories(userId: string, ids: string[]): RepositoryResponse<{ id: string }[]> {
    return repositoryResponse(() => this.prisma.story.findMany({
      where: { userId, id: { in: ids }, deletedAt: null },
      select: { id: true },
    }), 'Erro ao validar stories do destaque');
  }

  findById(id: string): RepositoryResponse<HighlightPayload | null> {
    return repositoryResponse(() => this.prisma.storyHighlight.findUnique({
      where: { id }, ...highlightPayload,
    }), 'Erro ao buscar destaque');
  }

  findVisibleById(id: string, viewerId: string): RepositoryResponse<HighlightPayload | null> {
    return repositoryResponse(() => this.prisma.storyHighlight.findUnique({
      where: { id },
      ...highlightPayload,
      include: {
        ...highlightPayload.include,
        stories: {
          ...highlightPayload.include.stories,
          where: { story: { deletedAt: null, ...storyAudienceWhere(viewerId) } },
        },
      },
    }), 'Erro ao buscar destaque');
  }

  findByUserId(userId: string, viewerId: string): RepositoryResponse<HighlightPayload[]> {
    return repositoryResponse(() => this.prisma.storyHighlight.findMany({
      where: { userId }, ...highlightPayload,
      include: {
        ...highlightPayload.include,
        stories: {
          ...highlightPayload.include.stories,
          where: { story: { deletedAt: null, ...storyAudienceWhere(viewerId) } },
        },
      },
      orderBy: { createdAt: 'asc' },
    }), 'Erro ao buscar destaques');
  }

  save(input: { id?: string; userId: string; title: string; coverStoryId: string; storyIds: string[] }): RepositoryResponse<HighlightPayload> {
    return repositoryResponse(() => this.prisma.$transaction(async (tx) => {
      const stories = input.storyIds.map((storyId, position) => ({ storyId, position }));
      if (input.id) {
        await tx.storyHighlightItem.deleteMany({ where: { highlightId: input.id } });
        return tx.storyHighlight.update({
          where: { id: input.id, userId: input.userId },
          data: { title: input.title, coverStoryId: input.coverStoryId, stories: { create: stories } },
          ...highlightPayload,
        });
      }
      return tx.storyHighlight.create({
        data: {
          userId: input.userId,
          title: input.title,
          coverStoryId: input.coverStoryId,
          stories: { create: stories },
        },
        ...highlightPayload,
      });
    }), 'Erro ao salvar destaque');
  }

  delete(id: string, userId: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.storyHighlight.delete({ where: { id, userId } });
    }, 'Erro ao excluir destaque');
  }
}
