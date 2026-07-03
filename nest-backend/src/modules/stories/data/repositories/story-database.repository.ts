import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { StoryRepository, StoryWithViews, StoryBrief, CreateStoryInput, StoryCreatePayload } from '../../domain/repositories/story.repository';

@Injectable()
export class PrismaStoryRepository implements StoryRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findActiveWithViews(): RepositoryResponse<StoryWithViews[]> {
    try {
      const stories = await this.prisma.story.findMany({
        where: { expiresAt: { gt: new Date() } },
        include: {
          user: { select: { id: true, displayName: true, avatarUrl: true } },
          _count: { select: { views: true } },
        },
        orderBy: { createdAt: 'desc' },
      });
      return right(stories as unknown as StoryWithViews[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar stories'));
    }
  }

  async findByUserId(userId: string): RepositoryResponse<StoryBrief[]> {
    try {
      const stories = await this.prisma.story.findMany({
        where: { userId, expiresAt: { gt: new Date() } },
        select: { id: true, imageUrl: true, createdAt: true, expiresAt: true },
        orderBy: { createdAt: 'desc' },
      });
      return right(stories as StoryBrief[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar stories do usuário'));
    }
  }

  async findById(id: string): RepositoryResponse<{ id: string; userId: string; imageUrl: string } | null> {
    try {
      const story = await this.prisma.story.findUnique({
        where: { id },
        select: { id: true, userId: true, imageUrl: true },
      });
      return right(story);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar story'));
    }
  }

  async create(data: CreateStoryInput): RepositoryResponse<StoryCreatePayload> {
    try {
      const story = await this.prisma.story.create({
        data,
        include: { user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } } },
      });
      return right(story);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar story'));
    }
  }

  async delete(id: string): RepositoryResponse<void> {
    try {
      await this.prisma.story.delete({ where: { id } });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao deletar story'));
    }
  }

  async upsertView(storyId: string, viewerId: string): RepositoryResponse<void> {
    try {
      await this.prisma.storyView.upsert({
        where: { storyId_viewerId: { storyId, viewerId } },
        create: { storyId, viewerId },
        update: { viewedAt: new Date() },
      });
      return right(void 0);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao registrar visualização'));
    }
  }
}
