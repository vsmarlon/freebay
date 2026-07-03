import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { CartService } from './cart.service';
import { AddToCartDTO, UpdateCartItemDTO, CartResponse, CheckoutCartResponse } from './dtos/cart.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { isLeft } from '@/shared/core/either';

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
    const result = await this.cartService.getCart(user.userId);
    if (isLeft(result)) throw result.value;
    return result.value;
  }

  @Post('checkout')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Checkout cart',
    description: 'Creates orders for all items in cart with PIX payment',
    auth: true,
    responseType: CheckoutCartResponse,
  })
  async checkout(@CurrentUser() user: AuthUser) {
    const result = await this.cartService.checkout({ userId: user.userId });
    if (isLeft(result)) throw result.value;
    return result.value;
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
    const result = await this.cartService.addToCart({
      userId: user.userId,
      productId,
      quantity: body.quantity ?? 1,
    });
    if (isLeft(result)) throw result.value;
    return result.value;
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
    const result = await this.cartService.updateCartItem({
      userId: user.userId,
      productId,
      quantity: body.quantity,
    });
    if (isLeft(result)) throw result.value;
    return result.value;
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
    const result = await this.cartService.removeFromCart({ userId: user.userId, productId });
    if (isLeft(result)) throw result.value;
    return result.value;
  }

  @Delete()
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Clear cart',
    auth: true,
  })
  async clearCart(@CurrentUser() user: AuthUser) {
    const result = await this.cartService.clearCart(user.userId);
    if (isLeft(result)) throw result.value;
    return result.value;
  }
}
