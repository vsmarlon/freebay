import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError } from "@/shared/core/errors";
import { PrismaStoryRepository } from "../data/repositories/story-database.repository";
import {
  CreateStoryInput,
  CreateStoryOutput,
  canonicalStoryTextBlocks,
} from "../dtos/stories.dto";

@Injectable()
export class CreateStoryUseCase {
  constructor(private readonly storyRepository: PrismaStoryRepository) {}

  async execute(
    input: CreateStoryInput,
  ): Promise<Either<AppError, CreateStoryOutput>> {
    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 24);

    const result = await this.storyRepository.create({
      user: { connect: { id: input.userId } },
      imageUrl: input.imageUrl,
      mediaType: input.mediaType ?? "IMAGE",
      caption: input.caption,
      textBlocks: input.textBlocks ?? [],
      expiresAt,
    });
    if (result.isLeft()) return left(result.value);

    const story = result.value;
    return right({
      id: story.id,
      userId: story.userId,
      imageUrl: story.imageUrl,
      mediaType: story.mediaType,
      caption: story.caption,
      textBlocks: canonicalStoryTextBlocks(story.textBlocks),
      expiresAt: story.expiresAt,
      createdAt: story.createdAt,
      user: story.user,
    });
  }
}
