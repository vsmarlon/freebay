import { Injectable } from "@nestjs/common";
import { GetStoriesUseCase } from "./usecases/get-stories.usecase";
import { GetUserStoriesUseCase } from "./usecases/get-user-stories.usecase";
import { CreateStoryUseCase } from "./usecases/create-story.usecase";
import { ViewStoryUseCase } from "./usecases/view-story.usecase";
import { DeleteStoryUseCase } from "./usecases/delete-story.usecase";
import { CreateStoryInput } from "./dtos/stories.dto";
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { HighlightPayload, StoryHighlightDatabaseRepository } from './data/repositories/story-highlight-database.repository';
import { SaveStoryHighlightInput, SaveStoryHighlightUseCase } from './usecases/save-story-highlight.usecase';
import { DeleteStoryHighlightUseCase } from './usecases/delete-story-highlight.usecase';
import { canonicalStoryTextBlocks } from './dtos/stories.dto';
import { storyMediaUrl } from './data/repositories/story-database.repository';

function toHighlightResponse(highlight: HighlightPayload) {
  const stories = highlight.stories
    .filter(({ story }) => story.deletedAt === null)
    .map(({ story }) => ({
      id: story.id,
      imageUrl: storyMediaUrl(story.imageUrl),
      mediaType: story.mediaType,
      audience: story.audience,
      caption: story.caption,
      textBlocks: canonicalStoryTextBlocks(story.textBlocks),
      createdAt: story.createdAt,
      expiresAt: story.expiresAt,
    }));
  return {
    id: highlight.id,
    title: highlight.title,
    user: highlight.user,
    coverStoryId: highlight.coverStoryId,
    coverUrl: stories.find((story) => story.id === highlight.coverStoryId)?.imageUrl ?? stories[0]?.imageUrl ?? '',
    stories,
  };
}

@Injectable()
export class StoriesService {
  constructor(
    private readonly getStoriesUseCase: GetStoriesUseCase,
    private readonly getUserStoriesUseCase: GetUserStoriesUseCase,
    private readonly createStoryUseCase: CreateStoryUseCase,
    private readonly viewStoryUseCase: ViewStoryUseCase,
    private readonly deleteStoryUseCase: DeleteStoryUseCase,
    private readonly highlights: StoryHighlightDatabaseRepository,
    private readonly saveHighlightUseCase: SaveStoryHighlightUseCase,
    private readonly deleteHighlightUseCase: DeleteStoryHighlightUseCase,
  ) {}

  async getStories(userId?: string) {
    return this.getStoriesUseCase.execute(userId);
  }

  async getUserStories(userId: string, viewerId: string) {
    return this.getUserStoriesUseCase.execute(userId, viewerId);
  }

  async createStory(input: CreateStoryInput) {
    return this.createStoryUseCase.execute(input);
  }

  async viewStory(input: { storyId: string; viewerId: string }) {
    return this.viewStoryUseCase.execute(input);
  }

  async deleteStory(input: { storyId: string; userId: string }) {
    return this.deleteStoryUseCase.execute(input);
  }

  async getArchive(userId: string) {
    const found = await this.highlights.findOwnerArchive(userId);
    if (found.isLeft()) return left(found.value);
    return right({ stories: found.value.map((story) => ({
      id: story.id,
      userId: story.userId,
      imageUrl: storyMediaUrl(story.imageUrl),
      mediaType: story.mediaType,
      audience: story.audience,
      caption: story.caption,
      textBlocks: canonicalStoryTextBlocks(story.textBlocks),
      createdAt: story.createdAt,
      expiresAt: story.expiresAt,
      user: story.user,
    })) });
  }

  async getHighlights(userId: string, viewerId: string) {
    const found = await this.highlights.findByUserId(userId, viewerId);
    if (found.isLeft()) return left(found.value);
    return right({ highlights: found.value.map(toHighlightResponse).filter((highlight) => highlight.stories.length > 0) });
  }

  async getHighlight(id: string, viewerId: string): Promise<Either<AppError, ReturnType<typeof toHighlightResponse>>> {
    const found = await this.highlights.findVisibleById(id, viewerId);
    if (found.isLeft()) return left(found.value);
    if (!found.value) return left(new NotFoundError('Destaque'));
    const highlight = toHighlightResponse(found.value);
    if (highlight.stories.length === 0) return left(new NotFoundError('Destaque'));
    return right(highlight);
  }

  saveHighlight(input: SaveStoryHighlightInput) {
    return this.saveHighlightUseCase.execute(input);
  }

  deleteHighlight(id: string, userId: string) {
    return this.deleteHighlightUseCase.execute(id, userId);
  }
}
