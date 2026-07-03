import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { StoryRepository } from '../domain/repositories/story.repository';

export interface GroupedStory {
  user: { id: string; displayName: string; avatarUrl: string | null };
  stories: {
    id: string;
    imageUrl: string;
    createdAt: Date;
    expiresAt: Date;
    viewsCount: number;
  }[];
}

@Injectable()
export class GetStoriesUseCase {
  constructor(private readonly storyRepository: StoryRepository) {}

  async execute(userId?: string): Promise<Either<AppError, { stories: GroupedStory[]; userHasStory: boolean }>> {
    const result = await this.storyRepository.findActiveWithViews();
    if (isLeft(result)) return left(result.value);

    const stories = result.value;
    const userHasStory = userId ? stories.some((s) => s.userId === userId) : false;

    const groupedByUser = stories.reduce<Record<string, GroupedStory>>((acc, story) => {
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
    }, {});

    return right({ stories: Object.values(groupedByUser), userHasStory });
  }
}
