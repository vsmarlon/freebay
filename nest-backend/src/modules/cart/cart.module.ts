import { Module } from '@nestjs/common';
import { CartController } from './cart.controller';
import { CartUseCasesModule } from './usecases/cart-usecases.module';

@Module({
  imports: [CartUseCasesModule],
  controllers: [CartController],
  exports: [CartUseCasesModule],
})
export class CartModule {}
