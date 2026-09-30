import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError } from "@/shared/core/errors";
import { PrismaStoryRepository } from "../data/repositories/story-database.repository";
import { StoryBrief } from "../types/story.types";

@Injectable()
export class GetUserStoriesUseCase {
  constructor(private readonly storyRepository: PrismaStoryRepository) {}

  async execute(userId: string, viewerId: string): Promise<Either<AppError, StoryBrief[]>> {
    const result = await this.storyRepository.findByUserId(userId, viewerId);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
