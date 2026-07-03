import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PostRepository } from '../domain/repositories/post.repository';
import { ShareRepository } from '../domain/repositories/share.repository';

@Injectable()
export class SharePostUseCase {
  constructor(
    private readonly postRepository: PostRepository,
    private readonly shareRepository: ShareRepository,
  ) {}

  async execute(input: { userId: string; postId: string }): Promise<Either<AppError, { shared: boolean }>> {
    const postResult = await this.postRepository.findById(input.postId);
    if (isLeft(postResult)) return left(postResult.value);
    if (!postResult.value) return left(new NotFoundError('Post'));

    const existingResult = await this.shareRepository.findByUserAndPost(input.userId, input.postId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (existingResult.value) return right({ shared: true });

    const createResult = await this.shareRepository.create({
      user: { connect: { id: input.userId } },
      post: { connect: { id: input.postId } },
    });
    if (isLeft(createResult)) return left(createResult.value);

    await this.postRepository.update(input.postId, { sharesCount: { increment: 1 } });
    return right({ shared: true });
  }
}
