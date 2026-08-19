import { Injectable } from '@nestjs/common';
import { CreateProductUseCase } from './usecases/create-product/create-product.usecase';
import { UpdateProductUseCase } from './usecases/update-product/update-product.usecase';
import { DeleteProductUseCase } from './usecases/delete-product/delete-product.usecase';
import { GetProductsUseCase } from './usecases/get-products/get-products.usecase';
import { GetProductByIdUseCase } from './usecases/get-products/get-product-by-id.usecase';
import { GetMyProductsUseCase } from './usecases/get-products/get-my-products.usecase';
import { CreateProductDTO, UpdateProductDTO, ProductQueryDTO } from './dtos/product.dto';
import { AuthUser } from '@/shared/core/types';
import { toDataUri } from '@/shared/utils/file.utils';
import { AppError } from '@/shared/core/errors';

@Injectable()
export class ProductsService {
  constructor(
    private readonly createProductUseCase: CreateProductUseCase,
    private readonly updateProductUseCase: UpdateProductUseCase,
    private readonly deleteProductUseCase: DeleteProductUseCase,
    private readonly getProductsUseCase: GetProductsUseCase,
    private readonly getProductByIdUseCase: GetProductByIdUseCase,
    private readonly getMyProductsUseCase: GetMyProductsUseCase,
  ) {}

  async findAll(query: ProductQueryDTO) {
    const result = await this.getProductsUseCase.execute(query);
    if (result.isLeft()) throw result.value;
    return result.value;
  }

  async findOne(id: string) {
    const result = await this.getProductByIdUseCase.execute(id);
    if (result.isLeft()) throw result.value;
    return result.value;
  }

  async findMyProducts(userId: string) {
    const result = await this.getMyProductsUseCase.execute(userId);
    if (result.isLeft()) throw result.value;
    return { products: result.value };
  }

  async create(user: AuthUser, file: Express.Multer.File | undefined, body: CreateProductDTO) {
    if (!file) throw new AppError('BAD_REQUEST', 'Imagem do produto é obrigatória');
    const dataUri = toDataUri(file);
    const result = await this.createProductUseCase.execute({
      sellerId: user.userId,
      ...body,
      images: [dataUri],
    });
    if (result.isLeft()) throw result.value;
    return { product: result.value };
  }

  async delete(productId: string, userId: string) {
    const result = await this.deleteProductUseCase.execute({ productId, userId });
    if (result.isLeft()) throw result.value;
    return { deleted: true };
  }

  async update(productId: string, userId: string, body: UpdateProductDTO) {
    const result = await this.updateProductUseCase.execute({ productId, userId, ...body });
    if (result.isLeft()) throw result.value;
    return { product: result.value };
  }
}
