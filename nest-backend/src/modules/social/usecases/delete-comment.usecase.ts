import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { PrismaCommentRepository } from '../data/repositories/comment-database.repository';

export interface DeleteCommentInput {
  commentId: string;
  userId: string;
}

@Injectable()
export class DeleteCommentUseCase {
  constructor(private readonly commentRepository: PrismaCommentRepository) {}

  async execute(input: DeleteCommentInput): Promise<Either<AppError, void>> {
    const comment = await this.commentRepository.findById(input.commentId);
    if (comment.isLeft()) return left(comment.value);
    if (!comment.value) return left(new NotFoundError('Comentário'));

    if (comment.value.userId !== input.userId) {
      return left(new ForbiddenError('Você não tem permissão para excluir este comentário'));
    }

    const deleteResult = await this.commentRepository.softDelete(input.commentId);
    if (deleteResult.isLeft()) return left(deleteResult.value);

    return right(undefined);
  }
}
