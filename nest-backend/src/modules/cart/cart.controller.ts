import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaCartRepository } from './repositories/cart.repository';
import { ZodValidationPipe } from '@/shared/pipes/zod-validation.pipe';
import { CheckoutCartDTO, checkoutCartSchema } from './dtos/cart.dto';
import { CheckoutCartUseCase } from './usecases/checkout-cart.usecase';

@Controller('cart')
@UseGuards(JwtAuthGuard, NonGuestGuard)
export class CartController {
  constructor(
    private readonly cartRepository: PrismaCartRepository,
    private readonly checkoutCartUseCase: CheckoutCartUseCase,
  ) {}

  @Get()
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
  async checkout(
    @CurrentUser() user: AuthUser,
    @Body(new ZodValidationPipe(checkoutCartSchema)) body: CheckoutCartDTO,
  ) {
    const result = await this.checkoutCartUseCase.execute({
      userId: user.userId,
      ...body,
    });

    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message, result.value.statusCode));
    }

    return result.value;
  }

  @Post(':productId')
  async addToCart(
    @Param('productId') productId: string,
    @CurrentUser() user: AuthUser,
    @Body() body?: { quantity?: number },
  ) {
    const quantity = Math.min(Math.max(body?.quantity ?? 1, 1), 10);
    const product = await this.cartRepository.findProductById(productId);

    if (!product || product.status !== 'ACTIVE') {
      return left(new AppError('NOT_FOUND', 'Produto não encontrado', 404));
    }

    if (product.sellerId === user.userId) {
      return left(new AppError('FORBIDDEN', 'Você não pode adicionar seu próprio produto ao carrinho', 403));
    }

    const item = await this.cartRepository.addOrIncrement(user.userId, productId, quantity);
    return { item };
  }

  @Patch(':productId')
  async updateCartItem(
    @Param('productId') productId: string,
    @CurrentUser() user: AuthUser,
    @Body() body: { quantity: number },
  ) {
    const quantity = body?.quantity;
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 10) {
      return left(new AppError('BAD_REQUEST', 'Quantidade deve ser entre 1 e 10', 400));
    }

    const existing = await this.cartRepository.findItem(user.userId, productId);
    if (!existing) {
      return left(new AppError('NOT_FOUND', 'Item não encontrado no carrinho', 404));
    }

    const item = await this.cartRepository.updateQuantity(user.userId, productId, quantity);
    return { item };
  }

  @Delete(':productId')
  async removeFromCart(@Param('productId') productId: string, @CurrentUser() user: AuthUser) {
    const existing = await this.cartRepository.findItem(user.userId, productId);
    if (!existing) {
      return left(new AppError('NOT_FOUND', 'Item não encontrado no carrinho', 404));
    }

    await this.cartRepository.remove(user.userId, productId);
    return { removed: true };
  }

  @Delete()
  async clearCart(@CurrentUser() user: AuthUser) {
    await this.cartRepository.clear(user.userId);
    return { cleared: true };
  }
}
