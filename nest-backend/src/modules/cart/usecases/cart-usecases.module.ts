import { Module } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
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
    { provide: PrismaClient, useExisting: PrismaService },
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
