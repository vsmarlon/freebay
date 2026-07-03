import { Module } from '@nestjs/common';
import { ProductRepository } from '../../domain/repositories/product.repository';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { DeleteProductUseCase } from './delete-product.usecase';

@Module({
  providers: [
    { provide: ProductRepository, useClass: ProductDatabaseRepository },
    DeleteProductUseCase,
  ],
  exports: [DeleteProductUseCase],
})
export class DeleteProductUseCaseModule {}
