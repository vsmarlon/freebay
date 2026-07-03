import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError } from '@/shared/core/errors';
import { StoryRepository } from '../domain/repositories/story.repository';

@Injectable()
export class DeleteStoryUseCase {
  constructor(private readonly storyRepository: StoryRepository) {}

  async execute(input: { storyId: string; userId: string }): Promise<Either<AppError, { deleted: boolean }>> {
    const storyResult = await this.storyRepository.findById(input.storyId);
    if (isLeft(storyResult)) return left(storyResult.value);
    if (!storyResult.value) return left(new NotFoundError('Story'));

    if (storyResult.value.userId !== input.userId) {
      return left(new UnauthorizedError('You can only delete your own stories'));
    }

    const deleteResult = await this.storyRepository.delete(input.storyId);
    if (isLeft(deleteResult)) return left(deleteResult.value);

    return right({ deleted: true });
  }
}
