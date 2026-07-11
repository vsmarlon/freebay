import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PostRepository } from '../domain/repositories/post.repository';
import { ShareRepository } from '../domain/repositories/share.repository';

@Injectable()
export class UnsharePostUseCase {
  constructor(
    private readonly postRepository: PostRepository,
    private readonly shareRepository: ShareRepository,
  ) {}

  async execute(input: { userId: string; postId: string }): Promise<Either<AppError, void>> {
    const existingResult = await this.shareRepository.findByUserAndPost(input.userId, input.postId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (!existingResult.value) return right(undefined);

    const deleteResult = await this.shareRepository.delete(input.userId, input.postId);
    if (isLeft(deleteResult)) return left(deleteResult.value);

    await this.postRepository.update(input.postId, { sharesCount: { decrement: 1 } });
    return right(undefined);
  }
}
