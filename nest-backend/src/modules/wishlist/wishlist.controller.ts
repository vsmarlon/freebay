import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaWishlistRepository } from './repositories/wishlist.repository';

@Controller('wishlist')
export class WishlistController {
  constructor(private readonly wishlistRepository: PrismaWishlistRepository) {}

  @Get()
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async getWishlist(@CurrentUser() user: AuthUser) {
    const wishlistItems = await this.wishlistRepository.getUserWishlist(user.userId);
    const products = wishlistItems.map((item) => item.product);
    return { products };
  }

  @Get('check/:productId')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async checkWishlist(@Param('productId') productId: string, @CurrentUser() user: AuthUser) {
    const item = await this.wishlistRepository.findByUserAndProduct(user.userId, productId);
    return { isInWishlist: !!item };
  }

  @Post(':productId')
  @UseGuards(JwtAuthGuard, NonGuestGuard)
  async toggleWishlist(@Param('productId') productId: string, @CurrentUser() user: AuthUser) {
    const product = await this.wishlistRepository.findProductById(productId);
    if (!product || product.status !== 'ACTIVE') {
      return left(new AppError('NOT_FOUND', 'Produto não encontrado', 404));
    }

    if (product.sellerId === user.userId) {
      return left(new AppError('FORBIDDEN', 'Você não pode adicionar seu próprio produto na wishlist', 403));
    }

    const existing = await this.wishlistRepository.findByUserAndProduct(user.userId, productId);
    if (existing) {
      await this.wishlistRepository.delete(user.userId, productId);
      return { inWishlist: false };
    }

    await this.wishlistRepository.create(user.userId, productId);
    return { inWishlist: true };
  }
}
