import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { PrismaLikeRepository } from '../data/repositories/like-database.repository';
import { LikePostInput } from '../dtos/social.dto';

@Injectable()
export class UnlikePostUseCase {
  constructor(
    private readonly postRepository: PrismaPostRepository,
    private readonly likeRepository: PrismaLikeRepository,
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
