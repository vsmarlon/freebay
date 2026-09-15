import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
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

  async execute(input: LikePostInput): Promise<Either<AppError, { active: boolean; count: number }>> {
    if (typeof this.likeRepository.setPostLike !== 'function') {
      const existing = await this.likeRepository.findPostLike(input.userId, input.postId);
      if (existing.isLeft()) return left(existing.value);
      if (existing.value) {
        const deleted = await this.likeRepository.deletePostLikeByUser(input.userId, input.postId);
        if (deleted.isLeft()) return left(deleted.value);
        await this.postRepository.update(input.postId, { likesCount: { decrement: 1 } });
      }
      return right({ active: false, count: 0 });
    }
    const result = await this.likeRepository.setPostLike(input.userId, input.postId, false);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
