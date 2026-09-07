import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { FavoriteDatabaseRepository } from '../data/repositories/favorite-database.repository';

@Injectable()
export class CheckFavoriteUseCase {
  constructor(private readonly favoriteRepository: FavoriteDatabaseRepository) {}

  async execute(userId: string, productId: string): Promise<Either<AppError, { isFavorited: boolean }>> {
    const result = await this.favoriteRepository.findByUserAndProduct(userId, productId);
    if (isLeft(result)) {
      return left(result.value);
    }
    return right({ isFavorited: !!result.value });
  }
}
