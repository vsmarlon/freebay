import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { NotFoundError, ForbiddenError, BadRequestError } from '@/shared/core/errors';
import { PrismaCartRepository } from './repositories/cart.repository';
import { CheckoutCartUseCase } from './usecases/checkout-cart.usecase';
import { AddToCartDTO, UpdateCartItemDTO, CartResponse, CheckoutCartResponse } from './dtos/cart.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

@ApiTags('Cart')
@Controller('cart')
@UseGuards(JwtAuthGuard, NonGuestGuard)
export class CartController {
  constructor(
    private readonly cartRepository: PrismaCartRepository,
    private readonly checkoutCartUseCase: CheckoutCartUseCase,
  ) {}

  @Get()
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get cart contents',
    auth: true,
    responseType: CartResponse,
  })
  async getCart(@CurrentUser() user: AuthUser) {
    const items = await this.cartRepository.getUserCart(user.userId);
    const totalItems = items.reduce((acc, item) => acc + item.quantity, 0);
    const totalPrice = items.reduce((acc, item) => acc + item.quantity * item.product.price, 0);

    return {
      items: items.map((item) => ({
        id: item.id,
        productId: item.productId,
        quantity: item.quantity,
        subtotal: item.quantity * item.product.price,
        product: item.product,
      })),
      totalItems,
      totalPrice,
    };
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
    const result = await this.checkoutCartUseCase.execute({
      userId: user.userId,
    });

    if (result.isLeft()) {
      throw result.value;
    }

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
    const quantity = Math.min(Math.max(body.quantity ?? 1, 1), 10);
    const product = await this.cartRepository.findProductById(productId);

    if (!product || product.status !== 'ACTIVE') {
      throw new NotFoundError('Produto');
    }

    if (product.sellerId === user.userId) {
      throw new ForbiddenError('Você não pode adicionar seu próprio produto ao carrinho');
    }

    const item = await this.cartRepository.addOrIncrement(user.userId, productId, quantity);
    return { item };
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
    const quantity = body.quantity;
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 10) {
      throw new BadRequestError('Quantidade deve ser entre 1 e 10');
    }

    const existing = await this.cartRepository.findItem(user.userId, productId);
    if (!existing) {
      throw new NotFoundError('Item no carrinho');
    }

    const item = await this.cartRepository.updateQuantity(user.userId, productId, quantity);
    return { item };
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
    const existing = await this.cartRepository.findItem(user.userId, productId);
    if (!existing) {
      throw new NotFoundError('Item no carrinho');
    }

    await this.cartRepository.remove(user.userId, productId);
    return { removed: true };
  }

  @Delete()
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Clear cart',
    auth: true,
  })
  async clearCart(@CurrentUser() user: AuthUser) {
    await this.cartRepository.clear(user.userId);
    return { cleared: true };
  }
}
