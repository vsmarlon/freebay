import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaSavedPostRepository } from '../data/repositories/saved-post-database.repository';

@Injectable()
export class UnsavePostUseCase {
  constructor(private readonly savedPostRepository: PrismaSavedPostRepository) {}

  async execute(input: { userId: string; postId: string }): Promise<Either<AppError, void>> {
    const existingResult = await this.savedPostRepository.findByUserAndPost(input.userId, input.postId);
    if (isLeft(existingResult)) return left(existingResult.value);
    if (!existingResult.value) return right(undefined);

    const unsaveResult = await this.savedPostRepository.unsave(input.userId, input.postId);
    if (isLeft(unsaveResult)) return left(unsaveResult.value);

    return right(undefined);
  }
}
