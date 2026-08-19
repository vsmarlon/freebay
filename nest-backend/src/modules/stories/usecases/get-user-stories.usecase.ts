import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { StoryRepository } from '../domain/repositories/story.repository';
import { StoryBrief } from '../types/story.types';

@Injectable()
export class GetUserStoriesUseCase {
  constructor(private readonly storyRepository: StoryRepository) {}

  async execute(userId: string): Promise<Either<AppError, StoryBrief[]>> {
    const result = await this.storyRepository.findByUserId(userId);
    if (isLeft(result)) return left(result.value);
    return right(result.value);
  }
}
