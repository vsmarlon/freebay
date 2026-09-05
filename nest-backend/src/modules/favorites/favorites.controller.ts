import { Controller, Param, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetAuth, PostAuth, CurrentUserId } from '@/shared/decorators';
import { GetFavoritesUseCase } from './usecases/get-favorites.usecase';
import { CheckFavoriteUseCase } from './usecases/check-favorite.usecase';
import { ToggleFavoriteUseCase } from './usecases/toggle-favorite.usecase';
import { FavoritesResponse, CheckFavoriteResponse, ToggleFavoriteResponse } from './dtos/favorite.dto';

@ApiTags('Favorites')
@Controller('favorites')
export class FavoritesController {
  constructor(
    private readonly getFavoritesUseCase: GetFavoritesUseCase,
    private readonly checkFavoriteUseCase: CheckFavoriteUseCase,
    private readonly toggleFavoriteUseCase: ToggleFavoriteUseCase,
  ) {}

  @GetAuth({
    summary: 'Get user favorites',
    responseType: FavoritesResponse,
  })
  async getFavorites(@CurrentUserId() userId: string) {
    return this.getFavoritesUseCase.execute(userId);
  }

  @GetAuth('check/:productId', {
    summary: 'Check if product is favorited',
    params: [{ name: 'productId', description: 'Product UUID' }],
    responseType: CheckFavoriteResponse,
  })
  async checkFavorite(@Param('productId', ParseUUIDPipe) productId: string, @CurrentUserId() userId: string) {
    return this.checkFavoriteUseCase.execute(userId, productId);
  }

  @PostAuth(':productId', {
    summary: 'Toggle favorite',
    description: 'Add or remove a product from favorites',
    params: [{ name: 'productId', description: 'Product UUID' }],
    responseType: ToggleFavoriteResponse,
    errors: [
      { status: 404, description: 'Product not found' },
      { status: 403, description: 'Cannot favorite own product' },
    ],
  })
  async toggleFavorite(@Param('productId', ParseUUIDPipe) productId: string, @CurrentUserId() userId: string) {
    return this.toggleFavoriteUseCase.execute(userId, productId);
  }
}

