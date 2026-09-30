import { Injectable } from "@nestjs/common";
import { Either, left, right } from "@/shared/core/either";
import { AppError, NotFoundError } from "@/shared/core/errors";
import { PrismaCommentRepository } from "../data/repositories/comment-database.repository";

@Injectable()
export class LikeCommentUseCase {
  constructor(private readonly commentRepository: PrismaCommentRepository) {}

  async execute(input: {
    userId: string;
    commentId: string;
  }): Promise<Either<AppError, void>> {
    const result = await this.commentRepository.setCommentLike(
      input.userId,
      input.commentId,
      true,
    );
    if (result.isLeft()) return left(result.value);
    return result.value ? right(undefined) : left(new NotFoundError('Comentário'));
  }
}
