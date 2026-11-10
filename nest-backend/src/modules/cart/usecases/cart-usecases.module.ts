import { Module } from '@nestjs/common';
import { CartDatabaseRepository } from '../data/repositories/cart-database.repository';
import { GetCartUseCase } from './get-cart.usecase';
import { AddToCartUseCase } from './add-to-cart.usecase';
import { UpdateCartItemUseCase } from './update-cart-item.usecase';
import { RemoveFromCartUseCase } from './remove-from-cart.usecase';
import { ClearCartUseCase } from './clear-cart.usecase';
import { CheckoutCartUseCase } from './checkout-cart.usecase';
import { GetCheckoutRecoveryUseCase } from './get-checkout-recovery.usecase';
import { PaymentsModule } from '@/modules/payments/payments.module';

@Module({
  imports: [PaymentsModule],
  providers: [
    CartDatabaseRepository,
    GetCartUseCase,
    AddToCartUseCase,
    UpdateCartItemUseCase,
    RemoveFromCartUseCase,
    ClearCartUseCase,
    CheckoutCartUseCase,
    GetCheckoutRecoveryUseCase,
  ],
  exports: [
    GetCartUseCase,
    AddToCartUseCase,
    UpdateCartItemUseCase,
    RemoveFromCartUseCase,
    ClearCartUseCase,
    CheckoutCartUseCase,
    GetCheckoutRecoveryUseCase,
  ],
})
export class CartUseCasesModule {}
