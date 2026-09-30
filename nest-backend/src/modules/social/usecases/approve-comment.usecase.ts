import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaCommentRepository } from '../data/repositories/comment-database.repository';

@Injectable()
export class ApproveCommentUseCase {
  constructor(private readonly comments: PrismaCommentRepository) {}

  async execute(commentId: string, ownerId: string): Promise<Either<AppError, void>> {
    const approved = await this.comments.approveHiddenComment(commentId, ownerId);
    if (approved.isLeft()) return left(approved.value);
    return approved.value ? right(undefined) : left(new NotFoundError('Comentário'));
  }
}
