import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaPostRepository, PrismaLikeRepository } from '../repositories/social.repository';
import { LikePostInput } from '../dtos/social.dto';

@Injectable()
export class LikePostUseCase {
  constructor(
    private postRepository: PrismaPostRepository,
    private likeRepository: PrismaLikeRepository,
  ) {}

  async execute(input: LikePostInput): Promise<Either<AppError, { liked: boolean }>> {
    const post = await this.postRepository.findById(input.postId);
    if (!post) {
      return left(new NotFoundError('Post'));
    }

    const existingLike = await this.likeRepository.findPostLike(input.userId, input.postId);
    if (existingLike) {
      return right({ liked: true });
    }

    await this.likeRepository.createLike({
      user: { connect: { id: input.userId } },
      post: { connect: { id: input.postId } },
    });
    await this.postRepository.incrementLikesCount(input.postId);
    return right({ liked: true });
  }
}
