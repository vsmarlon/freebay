import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError, NotFoundError } from "@/shared/core/errors";
import { PrismaStoryRepository } from "../data/repositories/story-database.repository";

@Injectable()
export class ViewStoryUseCase {
  constructor(private readonly storyRepository: PrismaStoryRepository) {}

  async execute(input: {
    storyId: string;
    viewerId: string;
  }): Promise<Either<AppError, void>> {
    const storyResult = await this.storyRepository.findById(input.storyId);
    if (storyResult.isLeft()) return left(storyResult.value);
    if (!storyResult.value) return left(new NotFoundError("Story"));

    if (input.viewerId) {
      const viewResult = await this.storyRepository.upsertView(
        input.storyId,
        input.viewerId,
      );
      if (viewResult.isLeft()) return left(viewResult.value);
    }

    return right(undefined);
  }
}
