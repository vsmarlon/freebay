import { Injectable } from '@nestjs/common';
import { Either, left, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { FavoriteRepository } from '../domain/repositories/favorite.repository';
import { FavoriteWithProduct } from '../types/favorite.types';

@Injectable()
export class GetFavoritesUseCase {
  constructor(private readonly favoriteRepository: FavoriteRepository) {}

  async execute(userId: string): Promise<Either<AppError, FavoriteWithProduct[]>> {
    const result = await this.favoriteRepository.getUserFavorites(userId);
    if (isLeft(result)) {
      return left(new AppError('DB_ERROR', 'Erro ao buscar favoritos'));
    }
    return result;
  }
}
