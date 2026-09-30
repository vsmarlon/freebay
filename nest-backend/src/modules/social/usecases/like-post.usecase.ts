import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { PrismaLikeRepository } from '../data/repositories/like-database.repository';
import { LikePostInput } from '../dtos/social.dto';

@Injectable()
export class LikePostUseCase {
  constructor(
    private readonly postRepository: PrismaPostRepository,
    private readonly likeRepository: PrismaLikeRepository,
  ) {}

  async execute(input: LikePostInput): Promise<Either<AppError, { active: boolean; count: number }>> {
    const postResult = await this.postRepository.findById(input.postId, input.userId);
    if (postResult.isLeft()) return left(postResult.value);
    if (!postResult.value) return left(new NotFoundError('Post'));

    if (typeof this.likeRepository.setPostLike !== 'function') {
      const existing = await this.likeRepository.findPostLike(input.userId, input.postId);
      if (existing.isLeft()) return left(existing.value);
      if (!existing.value) {
        const created = await this.likeRepository.createLike({ user: { connect: { id: input.userId } }, post: { connect: { id: input.postId } } });
        if (created.isLeft()) return left(created.value);
        await this.postRepository.update(input.postId, { likesCount: { increment: 1 } });
      }
      return right({ active: true, count: postResult.value.likesCount + (existing.value ? 0 : 1) });
    }
    const result = await this.likeRepository.setPostLike(input.userId, input.postId, true);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
