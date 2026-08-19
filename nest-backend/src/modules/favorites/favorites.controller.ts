import { Controller, Get, Param, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Authenticated } from '@/shared/decorators/endpoints.decorator';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { FavoritesService } from './favorites.service';
import { FavoritesResponse, CheckFavoriteResponse, ToggleFavoriteResponse } from './dtos/favorite.dto';

@ApiTags('Favorites')
@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get()
  @Authenticated({
    summary: 'Get user favorites',
    responseType: FavoritesResponse,
  })
  async getFavorites(@CurrentUser() user: AuthUser) {
    return this.favoritesService.getFavorites(user.userId);
  }

  @Get('check/:productId')
  @Authenticated({
    summary: 'Check if product is favorited',
    params: [{ name: 'productId', description: 'Product UUID' }],
    responseType: CheckFavoriteResponse,
  })
  async checkFavorite(@Param('productId') productId: string, @CurrentUser() user: AuthUser) {
    return this.favoritesService.checkFavorite(user.userId, productId);
  }

  @Post(':productId')
  @Authenticated({
    summary: 'Toggle favorite',
    description: 'Add or remove a product from favorites',
    params: [{ name: 'productId', description: 'Product UUID' }],
    responseType: ToggleFavoriteResponse,
    errors: [
      { status: 404, description: 'Product not found' },
      { status: 403, description: 'Cannot favorite own product' },
    ],
  })
  async toggleFavorite(@Param('productId') productId: string, @CurrentUser() user: AuthUser) {
    return this.favoritesService.toggleFavorite(user.userId, productId);
  }
}
