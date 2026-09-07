import { Injectable } from '@nestjs/common';
import { Either, left, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { FavoriteDatabaseRepository } from '../data/repositories/favorite-database.repository';
import { FavoriteWithProduct } from '../types/favorite.types';

@Injectable()
export class GetFavoritesUseCase {
  constructor(private readonly favoriteRepository: FavoriteDatabaseRepository) {}

  async execute(userId: string): Promise<Either<AppError, FavoriteWithProduct[]>> {
    const result = await this.favoriteRepository.getUserFavorites(userId);
    if (isLeft(result)) {
      return left(result.value);
    }
    return result;
  }
}
