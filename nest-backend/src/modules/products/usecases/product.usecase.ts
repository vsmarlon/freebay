import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError, BadRequestError } from '@/shared/core/errors';
import { PrismaProductRepository } from '../repositories/product.repository';
import { CreateProductInput, CreateProductOutput, DeleteProductInput, UpdateProductInput, UpdateProductOutput } from '../dtos/product.dto';

@Injectable()
export class CreateProductUseCase {
  private readonly logger = new Logger(CreateProductUseCase.name);

  constructor(private productRepository: PrismaProductRepository) {}

  async execute(
    input: CreateProductInput,
  ): Promise<Either<AppError, CreateProductOutput>> {
    this.logger.debug(
      `Creating product sellerId=${input.sellerId} title=${input.title} price=${input.price} categoryId=${input.categoryId} images=${input.images.length}`,
    );

    const imageUrls: { url: string; order: number }[] = [];

    for (let i = 0; i < input.images.length; i++) {
      const image = input.images[i];
      imageUrls.push({ url: image, order: i });
    }

    const product = await this.productRepository.create({
      title: input.title,
      description: input.description,
      price: input.price,
      condition: input.condition,
      category: { connect: { id: input.categoryId } },
      seller: { connect: { id: input.sellerId } },
      status: 'ACTIVE',
      images: {
        create: imageUrls,
      },
    });

    return right({
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      condition: product.condition as 'NEW' | 'USED',
      categoryId: product.categoryId!,
      sellerId: product.sellerId!,
      status: product.status,
      createdAt: product.createdAt,
    });
  }
}

@Injectable()
export class DeleteProductUseCase {
  constructor(private productRepository: PrismaProductRepository) {}

  async execute(
    input: DeleteProductInput,
  ): Promise<Either<AppError, { deleted: boolean }>> {
    const product = await this.productRepository.findById(input.productId);

    if (!product) {
      return left(new NotFoundError('Product'));
    }

    if (product.sellerId !== input.userId) {
      return left(new ForbiddenError('Você não pode excluir este produto'));
    }

    await this.productRepository.delete(input.productId);
    return right({ deleted: true });
  }
}

@Injectable()
export class UpdateProductUseCase {
  constructor(private productRepository: PrismaProductRepository) {}

  async execute(
    input: UpdateProductInput,
  ): Promise<Either<AppError, UpdateProductOutput>> {
    const product = await this.productRepository.findById(input.productId);

    if (!product) {
      return left(new NotFoundError('Product'));
    }

    if (product.sellerId !== input.userId) {
      return left(new ForbiddenError('Você não pode editar este produto'));
    }

    if (product.status === 'SOLD') {
      return left(new BadRequestError('Sold products cannot be edited'));
    }

    const updatedProduct = await this.productRepository.update(input.productId, {
      ...(input.title !== undefined ? { title: input.title } : {}),
      ...(input.description !== undefined ? { description: input.description } : {}),
      ...(input.price !== undefined ? { price: input.price } : {}),
      ...(input.condition !== undefined ? { condition: input.condition } : {}),
      ...(input.status !== undefined ? { status: input.status } : {}),
      ...(input.categoryId !== undefined
          ? { category: { connect: { id: input.categoryId } } }
          : {}),
    });

    return right({
      id: updatedProduct.id,
      title: updatedProduct.title,
      description: updatedProduct.description,
      price: updatedProduct.price,
      condition: updatedProduct.condition as 'NEW' | 'USED',
      categoryId: updatedProduct.categoryId!,
      sellerId: updatedProduct.sellerId!,
      status: updatedProduct.status,
      createdAt: updatedProduct.createdAt,
    });
  }
}
