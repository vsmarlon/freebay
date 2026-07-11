import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PostRepository } from '../domain/repositories/post.repository';
import { LikeRepository } from '../domain/repositories/like.repository';
import { LikePostInput } from '../dtos/social.dto';

@Injectable()
export class LikePostUseCase {
  constructor(
    private readonly postRepository: PostRepository,
    private readonly likeRepository: LikeRepository,
  ) {}

  async execute(input: LikePostInput): Promise<Either<AppError, void>> {
    const postResult = await this.postRepository.findById(input.postId);
    if (isLeft(postResult)) return left(postResult.value);
    if (!postResult.value) return left(new NotFoundError('Post'));

    const existingResult = await this.likeRepository.findPostLike(input.userId, input.postId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (existingResult.value) return right(undefined);

    const createResult = await this.likeRepository.createLike({
      user: { connect: { id: input.userId } },
      post: { connect: { id: input.postId } },
    });
    if (isLeft(createResult)) return left(createResult.value);

    await this.postRepository.update(input.postId, { likesCount: { increment: 1 } });
    return right(undefined);
  }
}
