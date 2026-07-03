import { Module } from '@nestjs/common';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { CreateProductUseCase } from './create-product.usecase';

@Module({
  providers: [
    { provide: ProductRepository, useClass: ProductDatabaseRepository },
    CreateProductUseCase,
  ],
  exports: [CreateProductUseCase],
})
export class CreateProductUseCaseModule {}
