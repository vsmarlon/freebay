import { Injectable } from '@nestjs/common';
import { isLeft } from '@/shared/core/either';
import { GetFavoritesUseCase } from './usecases/get-favorites.usecase';
import { CheckFavoriteUseCase } from './usecases/check-favorite.usecase';
import { ToggleFavoriteUseCase } from './usecases/toggle-favorite.usecase';

@Injectable()
export class FavoritesService {
  constructor(
    private readonly getFavoritesUseCase: GetFavoritesUseCase,
    private readonly checkFavoriteUseCase: CheckFavoriteUseCase,
    private readonly toggleFavoriteUseCase: ToggleFavoriteUseCase,
  ) {}

  async getFavorites(userId: string) {
    const result = await this.getFavoritesUseCase.execute(userId);
    if (isLeft(result)) throw result.value;
    return { products: result.value.map((f) => f.product) };
  }

  async checkFavorite(userId: string, productId: string) {
    const result = await this.checkFavoriteUseCase.execute(userId, productId);
    if (isLeft(result)) throw result.value;
    return result.value;
  }

  async toggleFavorite(userId: string, productId: string) {
    const result = await this.toggleFavoriteUseCase.execute(userId, productId);
    if (isLeft(result)) throw result.value;
    return result.value;
  }
}
