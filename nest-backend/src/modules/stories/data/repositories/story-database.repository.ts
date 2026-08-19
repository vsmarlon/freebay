import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { StoryRepository } from '../../domain/repositories/story.repository';
import { StoryWithViews, StoryBrief, CreateStoryInput, StoryCreatePayload } from '../../types/story.types';

@Injectable()
export class PrismaStoryRepository extends BasePrismaRepository implements StoryRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async findActiveWithViews(): RepositoryResponse<StoryWithViews[]> {
    return this.safeRun(async () => {
       return await this.prisma.story.findMany({
         where: { expiresAt: { gt: new Date() } },
         include: {
           user: { select: { id: true, displayName: true, avatarUrl: true } },
           _count: { select: { views: true } },
         },
         orderBy: { createdAt: 'desc' },
       });
    }, 'Erro ao buscar stories');
  }

  async findByUserId(userId: string): RepositoryResponse<StoryBrief[]> {
    return this.safeRun(async () => {
      const stories = await this.prisma.story.findMany({
        where: { userId, expiresAt: { gt: new Date() } },
        select: { id: true, imageUrl: true, createdAt: true, expiresAt: true },
        orderBy: { createdAt: 'desc' },
      });
      return stories as StoryBrief[];
    }, 'Erro ao buscar stories do usuário');
  }

  async findById(id: string): RepositoryResponse<{ id: string; userId: string; imageUrl: string } | null> {
    return this.safeRun(() => this.prisma.story.findUnique({
      where: { id },
      select: { id: true, userId: true, imageUrl: true },
    }), 'Erro ao buscar story');
  }

  async create(data: CreateStoryInput): RepositoryResponse<StoryCreatePayload> {
    return this.safeRun(() => this.prisma.story.create({
      data,
      include: { user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } } },
    }), 'Erro ao criar story');
  }

  async delete(id: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.story.delete({ where: { id } });
    }, 'Erro ao deletar story');
  }

  async upsertView(storyId: string, viewerId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.storyView.upsert({
        where: { storyId_viewerId: { storyId, viewerId } },
        create: { storyId, viewerId },
        update: { viewedAt: new Date() },
      });
    }, 'Erro ao registrar visualização');
  }
}
