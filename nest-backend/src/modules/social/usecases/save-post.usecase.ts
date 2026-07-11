import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PostRepository } from '../domain/repositories/post.repository';
import { SavedPostRepository } from '../domain/repositories/saved-post.repository';

@Injectable()
export class SavePostUseCase {
  constructor(
    private readonly postRepository: PostRepository,
    private readonly savedPostRepository: SavedPostRepository,
  ) {}

  async execute(input: { userId: string; postId: string }): Promise<Either<AppError, void>> {
    const postResult = await this.postRepository.findById(input.postId);
    if (isLeft(postResult)) return left(postResult.value);
    if (!postResult.value) return left(new NotFoundError('Post'));

    const existingResult = await this.savedPostRepository.findByUserAndPost(input.userId, input.postId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (existingResult.value) return right(undefined);

    const saveResult = await this.savedPostRepository.save(input.userId, input.postId);
    if (isLeft(saveResult)) return left(saveResult.value);

    return right(undefined);
  }
}
