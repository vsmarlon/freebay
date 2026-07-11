import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { LikeRepository } from '../domain/repositories/like.repository';

@Injectable()
export class LikeCommentUseCase {
  constructor(private readonly likeRepository: LikeRepository) {}

  async execute(input: { userId: string; commentId: string }): Promise<Either<AppError, void>> {
    const existingResult = await this.likeRepository.findCommentLike(input.userId, input.commentId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (existingResult.value) return right(undefined);

    const createResult = await this.likeRepository.createCommentLike({
      user: { connect: { id: input.userId } },
      comment: { connect: { id: input.commentId } },
    });
    if (isLeft(createResult)) return left(createResult.value);

    return right(undefined);
  }
}
