import { IStoryRepository } from '@/domain/repositories';
import { StoryEntity } from '@/domain/entities';
import { Either, right } from '@/domain/either';
import { AppError } from '@/domain/errors';

export class CreateStoryUseCase {
  constructor(private storyRepository: IStoryRepository) {}

  async execute(userId: string, imageUrl: string): Promise<Either<AppError, StoryEntity>> {
    const story = await this.storyRepository.createStory(userId, imageUrl);
    return right(story);
  }
}

export class GetStoriesUseCase {
  constructor(private storyRepository: IStoryRepository) {}

  async execute(
    userId: string,
  ): Promise<Either<AppError, { stories: StoryEntity[]; userHasStory: boolean }>> {
    const result = await this.storyRepository.getStories(userId);
    return right(result);
  }
}

export class DeleteStoryUseCase {
  constructor(private storyRepository: IStoryRepository) {}

  async execute(storyId: string, userId: string): Promise<Either<AppError, void>> {
    await this.storyRepository.deleteStory(storyId, userId);
    return right(undefined);
  }
}

export class ViewStoryUseCase {
  constructor(private storyRepository: IStoryRepository) {}

  async execute(storyId: string, viewerId: string): Promise<Either<AppError, void>> {
    await this.storyRepository.viewStory(storyId, viewerId);
    return right(undefined);
  }
}

export class GetUserStoriesUseCase {
  constructor(private storyRepository: IStoryRepository) {}

  async execute(userId: string, viewerId: string): Promise<Either<AppError, StoryEntity[]>> {
    const stories = await this.storyRepository.getUserStories(userId, viewerId);
    return right(stories);
  }
}
