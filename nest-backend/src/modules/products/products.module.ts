import { Module } from '@nestjs/common';
import { ProductsController } from './products.controller';
import { CreateProductUseCase } from './usecases/create-product/create-product.usecase';
import { UpdateProductUseCase } from './usecases/update-product/update-product.usecase';
import { DeleteProductUseCase } from './usecases/delete-product/delete-product.usecase';
import { GetProductsUseCase } from './usecases/get-products/get-products.usecase';
import { GetProductByIdUseCase } from './usecases/get-products/get-product-by-id.usecase';
import { GetMyProductsUseCase } from './usecases/get-products/get-my-products.usecase';
import { ProductDatabaseRepository } from './data/repositories/product-database.repository';

@Module({
  imports: [
  ],
  controllers: [ProductsController],
  providers: [
    ProductDatabaseRepository,
    CreateProductUseCase,
    UpdateProductUseCase,
    DeleteProductUseCase,
    GetProductsUseCase,
    GetProductByIdUseCase,
    GetMyProductsUseCase,
  ],
  exports: [
    ProductDatabaseRepository,
    CreateProductUseCase,
    UpdateProductUseCase,
    DeleteProductUseCase,
    GetProductsUseCase,
    GetProductByIdUseCase,
    GetMyProductsUseCase,
  ],
})
export class ProductsModule {}
