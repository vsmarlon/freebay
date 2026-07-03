import { Module } from '@nestjs/common';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { UpdateProductUseCase } from './update-product.usecase';

@Module({
  providers: [
    { provide: ProductRepository, useClass: ProductDatabaseRepository },
    UpdateProductUseCase,
  ],
  exports: [UpdateProductUseCase],
})
export class UpdateProductUseCaseModule {}
