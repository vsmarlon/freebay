import { Body, Controller, Param, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetAuth, PostAuth, PatchAuth, CurrentUserId } from '@/shared/decorators';
import { GetCartUseCase } from './usecases/get-cart.usecase';
import { AddToCartUseCase } from './usecases/add-to-cart.usecase';
import { UpdateCartItemUseCase } from './usecases/update-cart-item.usecase';
import { RemoveFromCartUseCase } from './usecases/remove-from-cart.usecase';
import { ClearCartUseCase } from './usecases/clear-cart.usecase';
import { CheckoutCartUseCase } from './usecases/checkout-cart.usecase';
import {
  AddToCartDTO,
  UpdateCartItemDTO,
  CheckoutCartDTO,
  CartResponse,
  CheckoutCartResponse,
} from './dtos/cart.dto';

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
    description:
      'Creates one order per cart item under a single Stripe payment. Either every order is created or none is. Pass mode=intent for the mobile PaymentSheet.',
    bodyType: CheckoutCartDTO,
    responseType: CheckoutCartResponse,
    throttle: { limit: 5, ttl: 60000 },
    errors: [
      { status: 400, description: 'Empty cart, missing CPF, or unavailable stock' },
    ],
  })
  async checkout(@CurrentUserId() userId: string, @Body() body: CheckoutCartDTO) {
    return this.checkoutCartUseCase.execute({ userId, mode: body.mode });
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

