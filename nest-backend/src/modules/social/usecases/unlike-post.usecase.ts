import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PostRepository } from '../domain/repositories/post.repository';
import { LikeRepository } from '../domain/repositories/like.repository';
import { LikePostInput } from '../dtos/social.dto';

@Injectable()
export class UnlikePostUseCase {
  constructor(
    private readonly postRepository: PostRepository,
    private readonly likeRepository: LikeRepository,
  ) {}

  async execute(input: LikePostInput): Promise<Either<AppError, void>> {
    const existingResult = await this.likeRepository.findPostLike(input.userId, input.postId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (!existingResult.value) return right(undefined);

    const deleteResult = await this.likeRepository.deletePostLikeByUser(input.userId, input.postId);
    if (isLeft(deleteResult)) return left(deleteResult.value);

    await this.postRepository.update(input.postId, { likesCount: { decrement: 1 } });
    return right(undefined);
  }
}
