import { Module } from '@nestjs/common';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { GetMyProductsUseCase } from './get-my-products.usecase';

@Module({
  providers: [
    { provide: ProductRepository, useClass: ProductDatabaseRepository },
    GetMyProductsUseCase,
  ],
  exports: [GetMyProductsUseCase],
})
export class GetMyProductsUseCaseModule {}
