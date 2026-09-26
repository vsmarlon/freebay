import { Injectable } from '@nestjs/common';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { Either, left, right } from '@/shared/core/either';
import { StoryHighlightDatabaseRepository } from '../data/repositories/story-highlight-database.repository';

export interface SaveStoryHighlightInput {
  id?: string;
  userId: string;
  title: string;
  storyIds: string[];
  coverStoryId: string;
}

@Injectable()
export class SaveStoryHighlightUseCase {
  constructor(private readonly repository: StoryHighlightDatabaseRepository) {}

  async execute(input: SaveStoryHighlightInput): Promise<Either<AppError, { id: string }>> {
    const title = input.title.trim();
    if (!title || input.storyIds.length === 0 || !input.storyIds.includes(input.coverStoryId)) {
      return left(new BadRequestError('Selecione stories, uma capa e um título'));
    }
    if (input.id) {
      const found = await this.repository.findById(input.id);
      if (found.isLeft()) return left(found.value);
      if (!found.value) return left(new NotFoundError('Destaque'));
      if (found.value.userId !== input.userId) return left(new ForbiddenError());
    }
    const owned = await this.repository.findOwnedStories(input.userId, input.storyIds);
    if (owned.isLeft()) return left(owned.value);
    if (owned.value.length !== input.storyIds.length) {
      return left(new BadRequestError('Selecione apenas seus próprios stories disponíveis'));
    }
    const saved = await this.repository.save({ ...input, title });
    if (saved.isLeft()) return left(saved.value);
    return right({ id: saved.value.id });
  }
}
