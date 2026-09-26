import { Injectable } from '@nestjs/common';
import { ProductStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { CreateProductInput, CreateProductOutput } from '../../dtos/product.dto';

@Injectable()
export class CreateProductUseCase {
  constructor(private readonly productRepository: ProductDatabaseRepository) {}

  async execute(input: CreateProductInput): Promise<Either<AppError, CreateProductOutput>> {
    const imageUrls = input.images.map((url, i) => ({ url, order: i }));

    const result = await this.productRepository.create({
      title: input.title,
      description: input.description,
      price: input.price,
      condition: input.condition,
      category: { connect: { id: input.categoryId } },
      seller: { connect: { id: input.sellerId } },
      status: ProductStatus.ACTIVE,
      quantity: input.quantity ?? 1,
      images: { create: imageUrls },
    });

    if (result.isLeft()) return left(result.value);
    const product = result.value;

    return right({
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      condition: product.condition as 'NEW' | 'USED',
      categoryId: product.categoryId!,
      sellerId: product.sellerId!,
      status: product.status,
      quantity: product.quantity,
      soldCount: product.soldCount,
      createdAt: product.createdAt,
    });
  }
}
