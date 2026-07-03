import { Injectable, Logger } from '@nestjs/common';
import { CreateProductUseCase } from './usecases/create-product/create-product.usecase';
import { UpdateProductUseCase } from './usecases/update-product/update-product.usecase';
import { DeleteProductUseCase } from './usecases/delete-product/delete-product.usecase';
import { GetProductsUseCase } from './usecases/get-products/get-products.usecase';
import { GetProductByIdUseCase } from './usecases/get-products/get-product-by-id.usecase';
import { GetMyProductsUseCase } from './usecases/get-products/get-my-products.usecase';
import { CreateProductDTO, UpdateProductDTO, ProductQueryDTO } from './dtos/product.dto';
import { AuthUser } from '@/shared/core/types';

@Injectable()
export class ProductsService {
  private readonly logger = new Logger(ProductsService.name);

  constructor(
    private readonly createProductUseCase: CreateProductUseCase,
    private readonly updateProductUseCase: UpdateProductUseCase,
    private readonly deleteProductUseCase: DeleteProductUseCase,
    private readonly getProductsUseCase: GetProductsUseCase,
    private readonly getProductByIdUseCase: GetProductByIdUseCase,
    private readonly getMyProductsUseCase: GetMyProductsUseCase,
  ) {}

  async findAll(query: ProductQueryDTO) {
    try {
      const result = await this.getProductsUseCase.execute(query);
      if (result.isRight()) return result.value;
      return { error: result.value.message };
    } catch (err) {
      this.logger.error(err);
      return { error: 'Erro ao listar produtos' };
    }
  }

  async findOne(id: string) {
    try {
      const result = await this.getProductByIdUseCase.execute(id);
      if (result.isRight()) return { product: result.value };
      return { error: result.value.message };
    } catch (err) {
      this.logger.error(err);
      return { error: 'Erro ao buscar produto' };
    }
  }

  async findMyProducts(userId: string) {
    try {
      const result = await this.getMyProductsUseCase.execute(userId);
      if (result.isRight()) return { products: result.value };
      return { error: result.value.message };
    } catch (err) {
      this.logger.error(err);
      return { error: 'Erro ao buscar seus produtos' };
    }
  }

  async create(user: AuthUser, file: Express.Multer.File | undefined, body: CreateProductDTO) {
    try {
      if (!file) return { error: 'Imagem do produto é obrigatória' };
      const dataUri = `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
      const result = await this.createProductUseCase.execute({
        sellerId: user.userId,
        ...body,
        images: [dataUri],
      });
      if (result.isRight()) return { product: result.value };
      return { error: result.value.message };
    } catch (err) {
      this.logger.error(err);
      return { error: 'Erro ao criar produto' };
    }
  }

  async delete(productId: string, userId: string) {
    try {
      const result = await this.deleteProductUseCase.execute({ productId, userId });
      if (result.isRight()) return { deleted: true };
      return { error: result.value.message };
    } catch (err) {
      this.logger.error(err);
      return { error: 'Erro ao excluir produto' };
    }
  }

  async update(productId: string, userId: string, body: UpdateProductDTO) {
    try {
      const result = await this.updateProductUseCase.execute({ productId, userId, ...body });
      if (result.isRight()) return { product: result.value };
      return { error: result.value.message };
    } catch (err) {
      this.logger.error(err);
      return { error: 'Erro ao atualizar produto' };
    }
  }
}
