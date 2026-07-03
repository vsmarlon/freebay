import { Injectable } from '@nestjs/common';
import { GetCartUseCase } from './usecases/get-cart.usecase';
import { AddToCartUseCase, AddToCartInput } from './usecases/add-to-cart.usecase';
import { UpdateCartItemUseCase, UpdateCartItemInput } from './usecases/update-cart-item.usecase';
import { RemoveFromCartUseCase, RemoveFromCartInput } from './usecases/remove-from-cart.usecase';
import { ClearCartUseCase } from './usecases/clear-cart.usecase';
import { CheckoutCartUseCase, CheckoutCartInput } from './usecases/checkout-cart.usecase';

@Injectable()
export class CartService {
  constructor(
    private readonly getCartUseCase: GetCartUseCase,
    private readonly addToCartUseCase: AddToCartUseCase,
    private readonly updateCartItemUseCase: UpdateCartItemUseCase,
    private readonly removeFromCartUseCase: RemoveFromCartUseCase,
    private readonly clearCartUseCase: ClearCartUseCase,
    private readonly checkoutCartUseCase: CheckoutCartUseCase,
  ) {}

  async getCart(userId: string) {
    return this.getCartUseCase.execute(userId);
  }

  async addToCart(input: AddToCartInput) {
    return this.addToCartUseCase.execute(input);
  }

  async updateCartItem(input: UpdateCartItemInput) {
    return this.updateCartItemUseCase.execute(input);
  }

  async removeFromCart(input: RemoveFromCartInput) {
    return this.removeFromCartUseCase.execute(input);
  }

  async clearCart(userId: string) {
    return this.clearCartUseCase.execute(userId);
  }

  async checkout(input: CheckoutCartInput) {
    return this.checkoutCartUseCase.execute(input);
  }
}
