import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { FavoritesService } from './favorites.service';
import { FavoritesResponse, CheckFavoriteResponse, ToggleFavoriteResponse } from './dtos/favorite.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

@ApiTags('Favorites')
@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Get()
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get user favorites',
    auth: true,
    responseType: FavoritesResponse,
  })
  async getFavorites(@CurrentUser() user: AuthUser) {
    return this.favoritesService.getFavorites(user.userId);
  }

  @Get('check/:productId')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Check if product is favorited',
    auth: true,
    params: [{ name: 'productId', description: 'Product UUID' }],
    responseType: CheckFavoriteResponse,
  })
  async checkFavorite(@Param('productId') productId: string, @CurrentUser() user: AuthUser) {
    return this.favoritesService.checkFavorite(user.userId, productId);
  }

  @Post(':productId')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Toggle favorite',
    description: 'Add or remove a product from favorites',
    auth: true,
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
