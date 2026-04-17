import { Module } from '@nestjs/common';
import { CartController } from './cart.controller';
import { PrismaCartRepository } from './repositories/cart.repository';
import { CheckoutCartUseCase } from './usecases/checkout-cart.usecase';
import { PaymentsModule } from '../payments/payments.module';

@Module({
  imports: [PaymentsModule],
  controllers: [CartController],
  providers: [PrismaCartRepository, CheckoutCartUseCase],
  exports: [PrismaCartRepository],
})
export class CartModule {}
