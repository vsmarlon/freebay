import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError } from "@/shared/core/errors";
import { PrismaStoryRepository } from "../data/repositories/story-database.repository";

import { GroupedStory } from "../dtos/stories.dto";
import { canonicalStoryTextBlocks } from "../dtos/stories.dto";

@Injectable()
export class GetStoriesUseCase {
  constructor(private readonly storyRepository: PrismaStoryRepository) {}

  async execute(
    userId?: string,
  ): Promise<
    Either<AppError, { stories: GroupedStory[]; userHasStory: boolean }>
  > {
    const result = await this.storyRepository.findActiveWithViews();
    if (result.isLeft()) return left(result.value);

    const stories = result.value;
    const userHasStory = userId
      ? stories.some((s) => s.userId === userId)
      : false;

    const groupedByUser = stories.reduce<Record<string, GroupedStory>>(
      (acc, story) => {
        const uid = story.userId;
        if (!acc[uid]) {
          acc[uid] = { user: story.user, stories: [] };
        }
        acc[uid].stories.push({
          id: story.id,
          imageUrl: story.imageUrl,
          mediaType: story.mediaType,
          caption: story.caption,
          textBlocks: canonicalStoryTextBlocks(story.textBlocks),
          createdAt: story.createdAt,
          expiresAt: story.expiresAt,
          viewsCount: story._count.views,
        });
        return acc;
      },
      {},
    );

    return right({ stories: Object.values(groupedByUser), userHasStory });
  }
}
