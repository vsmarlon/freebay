import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError } from "@/shared/core/errors";
import { CommentDatabaseRepository } from "../data/repositories/comment-database.repository";
import { MutationState } from "../types/social.types";

@Injectable()
export class UnlikeCommentUseCase {
  constructor(private readonly commentRepository: CommentDatabaseRepository) {}

  async execute(input: {
    userId: string;
    commentId: string;
  }): Promise<Either<AppError, MutationState>> {
    const result = await this.commentRepository.setCommentLike(
      input.userId,
      input.commentId,
      false,
    );
    if (result.isLeft()) return left(result.value);
    return right(result.value ?? { active: false, count: 0 });
  }
}
