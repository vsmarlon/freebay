import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError, NotFoundError } from "@/shared/core/errors";
import { CommentDatabaseRepository } from "../data/repositories/comment-database.repository";
import { MutationState } from "../types/social.types";

@Injectable()
export class LikeCommentUseCase {
  constructor(private readonly commentRepository: CommentDatabaseRepository) {}

  async execute(input: {
    userId: string;
    commentId: string;
  }): Promise<Either<AppError, MutationState>> {
    const result = await this.commentRepository.setCommentLike(
      input.userId,
      input.commentId,
      true,
    );
    if (result.isLeft()) return left(result.value);
    return result.value ? right(result.value) : left(new NotFoundError('Comentário'));
  }
}
