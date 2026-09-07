import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaPostRepository } from '../data/repositories/post-database.repository';
import { PrismaShareRepository } from '../data/repositories/share-database.repository';

@Injectable()
export class UnsharePostUseCase {
  constructor(
    private readonly postRepository: PrismaPostRepository,
    private readonly shareRepository: PrismaShareRepository,
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
