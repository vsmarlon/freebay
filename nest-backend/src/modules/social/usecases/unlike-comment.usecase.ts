import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaLikeRepository } from '../data/repositories/like-database.repository';

@Injectable()
export class UnlikeCommentUseCase {
  constructor(private readonly likeRepository: PrismaLikeRepository) {}

  async execute(input: { userId: string; commentId: string }): Promise<Either<AppError, void>> {
    const existingResult = await this.likeRepository.findCommentLike(input.userId, input.commentId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (!existingResult.value) return right(undefined);

    const deleteResult = await this.likeRepository.deleteCommentLike(input);
    if (isLeft(deleteResult)) return left(deleteResult.value);

    return right(undefined);
  }
}
