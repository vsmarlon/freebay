import { ILikeRepository, IPostRepository } from '@/domain/repositories';
import { Either, left, right } from '@/domain/either';
import { AppError, NotFoundError } from '@/domain/errors';

export class LikePostUseCase {
  constructor(
    private likeRepository: ILikeRepository,
    private postRepository: IPostRepository,
  ) {}

  async execute(userId: string, postId: string): Promise<Either<AppError, { liked: true }>> {
    const post = await this.postRepository.findById(postId);
    if (!post) {
      return left(new NotFoundError('Post'));
    }

    const existingLike = await this.likeRepository.findByUserAndPost(userId, postId);
    if (existingLike) {
      return right({ liked: true }); // already liked — idempotent
    }

    await this.likeRepository.create(userId, postId);
    await this.postRepository.incrementLikes(postId);

    return right({ liked: true });
  }
}

export class UnlikePostUseCase {
  constructor(
    private likeRepository: ILikeRepository,
    private postRepository: IPostRepository,
  ) {}

  async execute(userId: string, postId: string): Promise<Either<AppError, { unliked: true }>> {
    const existingLike = await this.likeRepository.findByUserAndPost(userId, postId);
    if (!existingLike) {
      return right({ unliked: true }); // not liked — idempotent
    }

    await this.likeRepository.delete(userId, postId);
    await this.postRepository.decrementLikes(postId);

    return right({ unliked: true });
  }
}
