import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { PrismaShareRepository } from '../data/repositories/share-database.repository';

@Injectable()
export class SharePostUseCase {
  constructor(
    private readonly postRepository: PrismaPostRepository,
    private readonly shareRepository: PrismaShareRepository,
  ) {}

  async execute(input: { userId: string; postId: string }): Promise<Either<AppError, { active: boolean; count: number }>> {
    const postResult = await this.postRepository.findById(input.postId);
    if (postResult.isLeft()) return left(postResult.value);
    if (!postResult.value) return left(new NotFoundError('Post'));

    const result = await this.shareRepository.setPostShare(input.userId, input.postId, true);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
