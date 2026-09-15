import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError } from "@/shared/core/errors";
import { PrismaCommentRepository } from "../data/repositories/comment-database.repository";

@Injectable()
export class UnlikeCommentUseCase {
  constructor(private readonly commentRepository: PrismaCommentRepository) {}

  async execute(input: {
    userId: string;
    commentId: string;
  }): Promise<Either<AppError, void>> {
    const result = await this.commentRepository.setCommentLike(
      input.userId,
      input.commentId,
      false,
    );
    return result.isLeft() ? left(result.value) : right(undefined);
  }
}
