import { Injectable } from "@nestjs/common";
import { PrismaService } from "@/shared/infra/prisma/prisma.service";
import { BasePrismaRepository } from "@/shared/infra/prisma/base-prisma.repository";
import { RepositoryResponse } from "@/shared/core/either";
import {
  StoryWithViews,
  StoryBrief,
  CreateStoryInput,
  StoryCreatePayload,
} from "../../types/story.types";
import { canonicalStoryTextBlocks } from "../../dtos/stories.dto";

@Injectable()
export class PrismaStoryRepository extends BasePrismaRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findActiveWithViews(): RepositoryResponse<StoryWithViews[]> {
    return this.safeRun(async () => {
      return await this.prisma.story.findMany({
        where: { expiresAt: { gt: new Date() }, deletedAt: null },
        include: {
          user: { select: { id: true, displayName: true, avatarUrl: true } },
          _count: { select: { views: true } },
        },
        orderBy: { createdAt: "desc" },
      });
    }, "Erro ao buscar stories");
  }

  async findByUserId(userId: string): RepositoryResponse<StoryBrief[]> {
    return this.safeRun(async () => {
      const stories = await this.prisma.story.findMany({
        where: { userId, expiresAt: { gt: new Date() }, deletedAt: null },
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
        imageUrl: story.imageUrl,
        mediaType: story.mediaType,
        caption: story.caption,
        textBlocks: canonicalStoryTextBlocks(story.textBlocks),
        createdAt: story.createdAt,
        expiresAt: story.expiresAt,
        user: story.user,
      }));
    }, "Erro ao buscar stories do usuário");
  }

  async findById(id: string): RepositoryResponse<{
    id: string;
    userId: string;
    imageUrl: string;
  } | null> {
    return this.safeRun(async () => {
      const story = await this.prisma.story.findUnique({
        where: { id },
        select: { id: true, userId: true, imageUrl: true, deletedAt: true },
      });
      if (!story || story.deletedAt !== null) return null;
      return { id: story.id, userId: story.userId, imageUrl: story.imageUrl };
    }, "Erro ao buscar story");
  }

  async create(data: CreateStoryInput): RepositoryResponse<StoryCreatePayload> {
    return this.safeRun(
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
    return this.safeRun(async () => {
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
    return this.safeRun(async () => {
      await this.prisma.storyView.upsert({
        where: { storyId_viewerId: { storyId, viewerId } },
        create: { storyId, viewerId },
        update: { viewedAt: new Date() },
      });
    }, "Erro ao registrar visualização");
  }
}
