import { Module } from '@nestjs/common';
import { ProductsController } from './products.controller';
import { ProductsService } from './products.service';
import { CreateProductUseCaseModule } from './usecases/create-product/create-product.usecase.module';
import { UpdateProductUseCaseModule } from './usecases/update-product/update-product.usecase.module';
import { DeleteProductUseCaseModule } from './usecases/delete-product/delete-product.usecase.module';
import { GetProductsUseCaseModule } from './usecases/get-products/get-products.usecase.module';
import { GetProductByIdUseCaseModule } from './usecases/get-products/get-product-by-id.usecase.module';
import { GetMyProductsUseCaseModule } from './usecases/get-products/get-my-products.usecase.module';

@Module({
  imports: [
    CreateProductUseCaseModule,
    UpdateProductUseCaseModule,
    DeleteProductUseCaseModule,
    GetProductsUseCaseModule,
    GetProductByIdUseCaseModule,
    GetMyProductsUseCaseModule,
  ],
  controllers: [ProductsController],
  providers: [ProductsController, ProductsService],
})
export class ProductsModule {}
