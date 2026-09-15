import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import {
  AppError,
  NotFoundError,
  UnauthorizedError,
} from "@/shared/core/errors";
import { PrismaStoryRepository } from "../data/repositories/story-database.repository";

@Injectable()
export class DeleteStoryUseCase {
  constructor(private readonly storyRepository: PrismaStoryRepository) {}

  async execute(input: {
    storyId: string;
    userId: string;
  }): Promise<Either<AppError, void>> {
    const storyResult = await this.storyRepository.findById(input.storyId);
    if (storyResult.isLeft()) return left(storyResult.value);
    if (!storyResult.value) return left(new NotFoundError("Story"));

    if (storyResult.value.userId !== input.userId) {
      return left(
        new UnauthorizedError("You can only delete your own stories"),
      );
    }

    const deleteResult = await this.storyRepository.delete(input.storyId);
    if (deleteResult.isLeft()) return left(deleteResult.value);

    return right(undefined);
  }
}
