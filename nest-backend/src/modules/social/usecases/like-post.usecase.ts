import { Injectable } from '@nestjs/common';
import { Either, left } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PostDatabaseRepository } from '../data/repositories/post-database.repository';
import { LikeDatabaseRepository } from '../data/repositories/like-database.repository';
import { LikePostInput } from '../dtos/social.dto';
import { MutationState } from '../types/social.types';

@Injectable()
export class LikePostUseCase {
  constructor(
    private readonly postRepository: PostDatabaseRepository,
    private readonly likeRepository: LikeDatabaseRepository,
  ) {}

  async execute(input: LikePostInput): Promise<Either<AppError, MutationState>> {
    const postResult = await this.postRepository.findById(input.postId, input.userId);
    if (postResult.isLeft()) return left(postResult.value);
    if (!postResult.value) return left(new NotFoundError('Post'));

    return this.likeRepository.setPostLike(input.userId, input.postId, true);
  }
}
