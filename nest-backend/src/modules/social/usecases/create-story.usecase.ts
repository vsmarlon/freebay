import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaStoryRepository } from '../repositories/social.repository';
import { CreateStoryInput, CreateStoryOutput } from '../dtos/social.dto';

@Injectable()
export class CreateStoryUseCase {
  constructor(private storyRepository: PrismaStoryRepository) {}

  async execute(input: CreateStoryInput): Promise<Either<AppError, CreateStoryOutput>> {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    const story = await this.storyRepository.create({
      user: { connect: { id: input.userId } },
      imageUrl: input.imageBase64,
      expiresAt,
    });

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
