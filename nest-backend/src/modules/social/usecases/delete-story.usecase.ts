import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, UnauthorizedError } from '@/shared/core/errors';
import { PrismaStoryRepository } from '../repositories/social.repository';

@Injectable()
export class DeleteStoryUseCase {
  constructor(private storyRepository: PrismaStoryRepository) {}

  async execute(input: { storyId: string; userId: string }): Promise<Either<AppError, { deleted: boolean }>> {
    const story = await this.storyRepository.findById(input.storyId);
    if (!story) {
      return left(new NotFoundError('Story'));
    }

    if (story.userId !== input.userId) {
      return left(new UnauthorizedError('You can only delete your own stories'));
    }

    await this.storyRepository.delete(input.storyId);
    return right({ deleted: true });
  }
}
