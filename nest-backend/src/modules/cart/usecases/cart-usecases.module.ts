import { Module } from '@nestjs/common';
import { CartRepository } from '../domain/repositories/cart.repository';
import { CartDatabaseRepository } from '../data/repositories/cart-database.repository';
import { GetCartUseCase } from './get-cart.usecase';
import { AddToCartUseCase } from './add-to-cart.usecase';
import { UpdateCartItemUseCase } from './update-cart-item.usecase';
import { RemoveFromCartUseCase } from './remove-from-cart.usecase';
import { ClearCartUseCase } from './clear-cart.usecase';
import { CheckoutCartUseCase } from './checkout-cart.usecase';
import { PaymentsModule } from '@/modules/payments/payments.module';

@Module({
  imports: [PaymentsModule],
  providers: [
    { provide: CartRepository, useClass: CartDatabaseRepository },
    GetCartUseCase,
    AddToCartUseCase,
    UpdateCartItemUseCase,
    RemoveFromCartUseCase,
    ClearCartUseCase,
    CheckoutCartUseCase,
  ],
  exports: [
    GetCartUseCase,
    AddToCartUseCase,
    UpdateCartItemUseCase,
    RemoveFromCartUseCase,
    ClearCartUseCase,
    CheckoutCartUseCase,
  ],
})
export class CartUseCasesModule {}
