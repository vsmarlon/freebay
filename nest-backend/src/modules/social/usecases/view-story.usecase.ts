import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaStoryRepository } from '../repositories/social.repository';

@Injectable()
export class ViewStoryUseCase {
  constructor(private storyRepository: PrismaStoryRepository) {}

  async execute(input: { storyId: string; viewerId: string }): Promise<Either<AppError, { viewed: boolean }>> {
    const story = await this.storyRepository.findById(input.storyId);
    if (!story) {
      return left(new NotFoundError('Story'));
    }

    if (input.viewerId) {
      await this.storyRepository.upsertView(input.storyId, input.viewerId);
    }

    return right({ viewed: true });
  }
}
