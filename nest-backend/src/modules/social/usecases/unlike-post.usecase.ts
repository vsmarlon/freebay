import { Injectable } from '@nestjs/common';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaPostRepository, PrismaLikeRepository } from '../repositories/social.repository';
import { LikePostInput } from '../dtos/social.dto';

@Injectable()
export class UnlikePostUseCase {
  constructor(
    private postRepository: PrismaPostRepository,
    private likeRepository: PrismaLikeRepository,
  ) {}

  async execute(input: LikePostInput): Promise<Either<AppError, { unliked: boolean }>> {
    const existingLike = await this.likeRepository.findPostLike(input.userId, input.postId);
    if (!existingLike) {
      return right({ unliked: true });
    }
    await this.likeRepository.deletePostLikeByUser(input.userId, input.postId);
    await this.postRepository.decrementLikesCount(input.postId);
    return right({ unliked: true });
  }
}
