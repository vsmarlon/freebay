import { Module } from '@nestjs/common';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { GetProductsUseCase } from './get-products.usecase';

@Module({
  providers: [
    { provide: ProductRepository, useClass: ProductDatabaseRepository },
    GetProductsUseCase,
  ],
  exports: [GetProductsUseCase],
})
export class GetProductsUseCaseModule {}
