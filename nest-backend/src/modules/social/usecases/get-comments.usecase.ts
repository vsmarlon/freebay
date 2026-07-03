import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CommentRepository } from '../domain/repositories/comment.repository';
import { CommentPayload } from '../types/social.types';

@Injectable()
export class GetCommentsUseCase {
  constructor(private readonly commentRepository: CommentRepository) {}

  async execute(input: { postId: string; limit?: number; offset?: number }): Promise<Either<AppError, CommentPayload[]>> {
    const result = await this.commentRepository.findByPostId(input.postId, {
      limit: input.limit,
      offset: input.offset,
    });
    if (isLeft(result)) return left(result.value);
    return right(result.value);
  }
}
