import { Injectable } from '@nestjs/common';
import { AppError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { Either, left, right } from '@/shared/core/either';
import { StoryHighlightDatabaseRepository } from '../data/repositories/story-highlight-database.repository';

@Injectable()
export class DeleteStoryHighlightUseCase {
  constructor(private readonly repository: StoryHighlightDatabaseRepository) {}

  async execute(id: string, userId: string): Promise<Either<AppError, void>> {
    const found = await this.repository.findById(id);
    if (found.isLeft()) return left(found.value);
    if (!found.value) return left(new NotFoundError('Destaque'));
    if (found.value.userId !== userId) return left(new ForbiddenError());
    const deleted = await this.repository.delete(id, userId);
    if (deleted.isLeft()) return left(deleted.value);
    return right(undefined);
  }
}
