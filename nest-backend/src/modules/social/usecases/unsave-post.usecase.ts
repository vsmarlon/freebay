import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaSavedPostRepository } from '../data/repositories/saved-post-database.repository';

@Injectable()
export class UnsavePostUseCase {
  constructor(private readonly savedPostRepository: PrismaSavedPostRepository) {}

  async execute(input: { userId: string; postId: string }): Promise<Either<AppError, { active: boolean }>> {
    const result = await this.savedPostRepository.setSaved(input.userId, input.postId, false);
    if (result.isLeft()) return left(result.value);
    return right(result.value);
  }
}
