import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { CartService } from './cart.service';
import { AddToCartDTO, UpdateCartItemDTO, CartResponse, CheckoutCartResponse } from './dtos/cart.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

@ApiTags('Cart')
@Controller('cart')
@UseGuards(JwtAuthGuard, NonGuestGuard)
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Get()
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get cart contents',
    auth: true,
    responseType: CartResponse,
  })
  async getCart(@CurrentUser() user: AuthUser) {
    return this.cartService.getCart(user.userId);
  }

  @Post('checkout')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Checkout cart',
    description: 'Creates orders for all items in cart with Stripe payment sessions',
    auth: true,
    responseType: CheckoutCartResponse,
  })
  async checkout(@CurrentUser() user: AuthUser) {
    return this.cartService.checkout({ userId: user.userId });
  }

  @Post(':productId')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Add product to cart',
    auth: true,
    bodyType: AddToCartDTO,
    params: [{ name: 'productId', description: 'Product UUID' }],
    errors: [
      { status: 404, description: 'Product not found' },
      { status: 403, description: 'Cannot add own product' },
    ],
  })
  async addToCart(
    @Param('productId') productId: string,
    @CurrentUser() user: AuthUser,
    @Body() body: AddToCartDTO,
  ) {
    return this.cartService.addToCart({
      userId: user.userId,
      productId,
      quantity: body.quantity ?? 1,
    });
  }

  @Patch(':productId')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Update cart item quantity',
    auth: true,
    bodyType: UpdateCartItemDTO,
    params: [{ name: 'productId', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Item not found in cart' }],
  })
  async updateCartItem(
    @Param('productId') productId: string,
    @CurrentUser() user: AuthUser,
    @Body() body: UpdateCartItemDTO,
  ) {
    return this.cartService.updateCartItem({
      userId: user.userId,
      productId,
      quantity: body.quantity,
    });
  }

  @Delete(':productId')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Remove item from cart',
    auth: true,
    params: [{ name: 'productId', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Item not found in cart' }],
  })
  async removeFromCart(@Param('productId') productId: string, @CurrentUser() user: AuthUser) {
    return this.cartService.removeFromCart({ userId: user.userId, productId });
  }

  @Delete()
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Clear cart',
    auth: true,
  })
  async clearCart(@CurrentUser() user: AuthUser) {
    return this.cartService.clearCart(user.userId);
  }
}
