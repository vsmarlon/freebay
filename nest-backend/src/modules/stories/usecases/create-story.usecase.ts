import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { StoryRepository } from '../domain/repositories/story.repository';
import { CreateStoryInput, CreateStoryOutput } from '../dtos/stories.dto';

@Injectable()
export class CreateStoryUseCase {
  constructor(private readonly storyRepository: StoryRepository) {}

  async execute(input: CreateStoryInput): Promise<Either<AppError, CreateStoryOutput>> {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    const result = await this.storyRepository.create({
      user: { connect: { id: input.userId } },
      imageUrl: input.imageBase64,
      expiresAt,
    });
    if (isLeft(result)) return left(result.value);

    const story = result.value;
    return right({
      id: story.id,
      userId: story.userId,
      imageUrl: story.imageUrl,
      expiresAt: story.expiresAt,
      createdAt: story.createdAt,
      user: story.user,
    });
  }
}
