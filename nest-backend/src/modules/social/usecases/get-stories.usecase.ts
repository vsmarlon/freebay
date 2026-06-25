import { Injectable } from '@nestjs/common';
import { PrismaStoryRepository } from '../repositories/social.repository';

@Injectable()
export class GetStoriesUseCase {
  constructor(private storyRepository: PrismaStoryRepository) {}

  async execute(userId?: string) {
    const stories = await this.storyRepository.findActiveWithViews();

    let userHasStory = false;
    if (userId) {
      userHasStory = stories.some(s => s.userId === userId);
    }

    const groupedByUser = stories.reduce<Record<string, { user: unknown; stories: unknown[] }>>((acc, story) => {
      const uid = story.userId;
      if (!acc[uid]) {
        acc[uid] = { user: story.user, stories: [] };
      }
      acc[uid].stories.push({
        id: story.id,
        imageUrl: story.imageUrl,
        createdAt: story.createdAt,
        expiresAt: story.expiresAt,
        viewsCount: story._count.views,
      });
      return acc;
    }, {} as Record<string, { user: unknown; stories: unknown[] }>);

    return { stories: Object.values(groupedByUser), userHasStory };
  }
}
