import { Body, Controller, Param, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetAuth, PostAuth, PatchAuth, CurrentUserId } from '@/shared/decorators';
import { GetCartUseCase } from './usecases/get-cart.usecase';
import { AddToCartUseCase } from './usecases/add-to-cart.usecase';
import { UpdateCartItemUseCase } from './usecases/update-cart-item.usecase';
import { RemoveFromCartUseCase } from './usecases/remove-from-cart.usecase';
import { ClearCartUseCase } from './usecases/clear-cart.usecase';
import { CheckoutCartUseCase } from './usecases/checkout-cart.usecase';
import { AddToCartDTO, UpdateCartItemDTO, CartResponse, CheckoutCartResponse } from './dtos/cart.dto';

@ApiTags('Cart')
@Controller('cart')
export class CartController {
  constructor(
    private readonly getCartUseCase: GetCartUseCase,
    private readonly addToCartUseCase: AddToCartUseCase,
    private readonly updateCartItemUseCase: UpdateCartItemUseCase,
    private readonly removeFromCartUseCase: RemoveFromCartUseCase,
    private readonly clearCartUseCase: ClearCartUseCase,
    private readonly checkoutCartUseCase: CheckoutCartUseCase,
  ) {}

  @GetAuth({
    summary: 'Get cart contents',
    responseType: CartResponse,
  })
  async getCart(@CurrentUserId() userId: string) {
    return this.getCartUseCase.execute(userId);
  }

  @PostAuth('checkout', {
    summary: 'Checkout cart',
    description: 'Creates orders for all items in cart with Stripe payment sessions',
    responseType: CheckoutCartResponse,
  })
  async checkout(@CurrentUserId() userId: string) {
    return this.checkoutCartUseCase.execute({ userId });
  }

  @PostAuth(':productId', {
    summary: 'Add product to cart',
    bodyType: AddToCartDTO,
    params: [{ name: 'productId', description: 'Product UUID' }],
    errors: [
      { status: 404, description: 'Product not found' },
      { status: 403, description: 'Cannot add own product' },
    ],
  })
  async addToCart(
    @Param('productId', ParseUUIDPipe) productId: string,
    @CurrentUserId() userId: string,
    @Body() body: AddToCartDTO,
  ) {
    return this.addToCartUseCase.execute({
      userId,
      productId,
      quantity: body.quantity ?? 1,
    });
  }

  @PatchAuth(':productId', {
    summary: 'Update cart item quantity',
    bodyType: UpdateCartItemDTO,
    params: [{ name: 'productId', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Item not found in cart' }],
  })
  async updateCartItem(
    @Param('productId', ParseUUIDPipe) productId: string,
    @CurrentUserId() userId: string,
    @Body() body: UpdateCartItemDTO,
  ) {
    return this.updateCartItemUseCase.execute({
      userId,
      productId,
      quantity: body.quantity,
    });
  }

  @PatchAuth(':productId/remove', {
    summary: 'Remove item from cart',
    params: [{ name: 'productId', description: 'Product UUID' }],
    errors: [{ status: 404, description: 'Item not found in cart' }],
  })
  async removeFromCart(@Param('productId', ParseUUIDPipe) productId: string, @CurrentUserId() userId: string) {
    return this.removeFromCartUseCase.execute({ userId, productId });
  }

  @PatchAuth('clear', 'Clear cart')
  async clearCart(@CurrentUserId() userId: string) {
    return this.clearCartUseCase.execute(userId);
  }
}

