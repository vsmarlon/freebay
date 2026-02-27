import { IProductRepository } from '@/domain/repositories';
import { ProductEntity } from '@/domain/entities';
import { Either, right, left } from '@/domain/either';
import { AppError, NotFoundError } from '@/domain/errors';
import { CreateProductInput } from './input/CreateProductInput';

export class CreateProductUseCase {
  constructor(private productRepository: IProductRepository) {}

  async execute(input: CreateProductInput): Promise<Either<AppError, ProductEntity>> {
    const product = await this.productRepository.create({
      title: input.title,
      description: input.description,
      price: input.price,
      condition: input.condition,
      categoryId: input.categoryId ?? null,
      status: 'ACTIVE',
      sellerId: input.sellerId,
      postId: null,
    });
    return right(product);
  }
}

export class SearchProductsUseCase {
  constructor(private productRepository: IProductRepository) {}

  async execute(params: {
    cursor?: string;
    limit?: number;
    search?: string;
    category?: string;
    minPrice?: number;
    maxPrice?: number;
  }): Promise<Either<AppError, ProductEntity[]>> {
    const products = await this.productRepository.findAll(params);
    return right(products);
  }
}

export class GetProductUseCase {
  constructor(private productRepository: IProductRepository) {}

  async execute(id: string): Promise<Either<AppError, ProductEntity>> {
    const product = await this.productRepository.findById(id);
    if (!product) {
      return left(new NotFoundError('Produto'));
    }
    return right(product);
  }
}
