import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class PrismaStoryRepository {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    return this.prisma.story.findMany({
      where: { createdAt: { gte: yesterday } },
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { id: true, displayName: true, avatarUrl: true } } },
    });
  }

  async findActiveWithViews() {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    return this.prisma.story.findMany({
      where: {
        createdAt: { gte: yesterday },
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
      include: {
        user: { select: { id: true, displayName: true, avatarUrl: true, isVerified: true } },
        _count: { select: { views: true } },
      },
    });
  }

  async findByUserId(userId: string) {
    return this.prisma.story.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string) {
    return this.prisma.story.findUnique({ where: { id } });
  }

  async create(data: Prisma.StoryCreateInput) {
    return this.prisma.story.create({ data });
  }

  async delete(id: string) {
    return this.prisma.story.delete({ where: { id } });
  }

  async upsertView(storyId: string, viewerId: string) {
    return this.prisma.storyView.upsert({
      where: { storyId_viewerId: { storyId, viewerId } },
      create: { story: { connect: { id: storyId } }, viewerId },
      update: { viewedAt: new Date() },
    });
  }
}
