import { Injectable } from "@nestjs/common";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from "@/shared/core/either";
import {
  StoryWithViews,
  StoryBrief,
  CreateStoryInput,
  StoryCreatePayload,
} from "../../types/story.types";
import { canonicalStoryTextBlocks } from "../../dtos/stories.dto";
import { Prisma } from '@prisma/client';

export function storyAudienceWhere(viewerId: string): Prisma.StoryWhereInput {
  return {
    OR: [
      { userId: viewerId },
      {
        user: {
          blocksGiven: { none: { blockedId: viewerId } },
          blocksReceived: { none: { blockerId: viewerId } },
        },
        OR: [
          { audience: 'EVERYONE' },
          {
            audience: 'CLOSE_FRIENDS',
            user: {
              closeFriendsGiven: { some: { memberId: viewerId } },
              OR: [
                { following: { some: { followingId: viewerId } } },
                { followers: { some: { followerId: viewerId } } },
              ],
            },
          },
        ],
      },
    ],
  };
}

export function storyMediaUrl(url: string): string {
  return url.replace(/^\/uploads\/story\//, '/media/story/');
}

@Injectable()
export class PrismaStoryRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async findActiveWithViews(viewerId: string): RepositoryResponse<StoryWithViews[]> {
    return repositoryResponse(async () => {
      return await this.prisma.story.findMany({
        where: { expiresAt: { gt: new Date() }, deletedAt: null, ...storyAudienceWhere(viewerId) },
        include: {
          user: { select: { id: true, displayName: true, avatarUrl: true } },
          _count: { select: { views: true } },
        },
        orderBy: { createdAt: "desc" },
      });
    }, "Erro ao buscar stories");
  }

  async findByUserId(userId: string, viewerId: string): RepositoryResponse<StoryBrief[]> {
    return repositoryResponse(async () => {
      const stories = await this.prisma.story.findMany({
        where: { userId, expiresAt: { gt: new Date() }, deletedAt: null, ...storyAudienceWhere(viewerId) },
        include: {
          user: {
            select: {
              id: true,
              displayName: true,
              avatarUrl: true,
              isVerified: true,
            },
          },
        },
        orderBy: { createdAt: "desc" },
      });
      return stories.map((story) => ({
        id: story.id,
        imageUrl: storyMediaUrl(story.imageUrl),
        audience: story.audience,
        mediaType: story.mediaType,
        caption: story.caption,
        textBlocks: canonicalStoryTextBlocks(story.textBlocks),
        createdAt: story.createdAt,
        expiresAt: story.expiresAt,
        user: story.user,
      }));
    }, "Erro ao buscar stories do usuário");
  }

  async findById(id: string, viewerId?: string): RepositoryResponse<{
    id: string;
    userId: string;
    imageUrl: string;
  } | null> {
    return repositoryResponse(async () => {
      const story = await this.prisma.story.findUnique({
        where: { ...(viewerId ? { expiresAt: { gt: new Date() }, ...storyAudienceWhere(viewerId) } : {}), id },
        select: { id: true, userId: true, imageUrl: true, deletedAt: true },
      });
      if (!story || story.deletedAt !== null) return null;
      return { id: story.id, userId: story.userId, imageUrl: story.imageUrl };
    }, "Erro ao buscar story");
  }

  async create(data: CreateStoryInput): RepositoryResponse<StoryCreatePayload> {
    return repositoryResponse(
      () =>
        this.prisma.story.create({
          data,
          include: {
            user: {
              select: {
                id: true,
                displayName: true,
                avatarUrl: true,
                isVerified: true,
              },
            },
          },
        }),
      "Erro ao criar story",
    );
  }

  async delete(id: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.story.update({
        where: { id },
        data: { deletedAt: new Date() },
      });
    }, "Erro ao deletar story");
  }

  async upsertView(
    storyId: string,
    viewerId: string,
  ): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.storyView.upsert({
        where: { storyId_viewerId: { storyId, viewerId } },
        create: { storyId, viewerId },
        update: { viewedAt: new Date() },
      });
    }, "Erro ao registrar visualização");
  }
}
