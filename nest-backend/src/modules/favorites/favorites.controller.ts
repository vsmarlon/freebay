import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaFavoriteRepository } from './repositories/favorite.repository';

@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoriteRepository: PrismaFavoriteRepository) {}

  @Get()
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async getFavorites(@CurrentUser() user: AuthUser) {
    const favorites = await this.favoriteRepository.getUserFavorites(user.userId);
    const products = favorites.map((favorite) => favorite.product);
    return { products };
  }

  @Get('check/:productId')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async checkFavorite(@Param('productId') productId: string, @CurrentUser() user: AuthUser) {
    const favorite = await this.favoriteRepository.findByUserAndProduct(user.userId, productId);
    return { isFavorited: !!favorite };
  }

  @Post(':productId')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async toggleFavorite(@Param('productId') productId: string, @CurrentUser() user: AuthUser) {
    const product = await this.favoriteRepository.findProductById(productId);
    if (!product || product.status !== 'ACTIVE') {
      return left(new AppError('NOT_FOUND', 'Produto não encontrado', 404));
    }

    if (product.sellerId === user.userId) {
      return left(new AppError('FORBIDDEN', 'Você não pode favoritar seu próprio produto', 403));
    }

    const existing = await this.favoriteRepository.findByUserAndProduct(user.userId, productId);
    if (existing) {
      await this.favoriteRepository.delete(user.userId, productId);
      return { favorited: false };
    }

    await this.favoriteRepository.create(user.userId, productId);
    return { favorited: true };
  }
}
