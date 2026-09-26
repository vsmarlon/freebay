import { Injectable } from '@nestjs/common';
import { ProductStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError, BadRequestError } from '@/shared/core/errors';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { UpdateProductInput, UpdateProductOutput } from '../../dtos/product.dto';

@Injectable()
export class UpdateProductUseCase {
  constructor(private readonly productRepository: ProductDatabaseRepository) {}

  async execute(input: UpdateProductInput): Promise<Either<AppError, UpdateProductOutput>> {
    const product = await this.productRepository.findById(input.productId);
    if (product.isLeft()) return left(product.value);
    if (!product.value) return left(new NotFoundError('Product'));

    if (product.value.sellerId !== input.userId) {
      return left(new ForbiddenError('Você não pode editar este produto'));
    }

    if (product.value.status === ProductStatus.SOLD) {
      return left(new BadRequestError('Sold products cannot be edited'));
    }

    const updateData: Record<string, unknown> = {};
    if (input.title !== undefined) updateData.title = input.title;
    if (input.description !== undefined) updateData.description = input.description;
    if (input.price !== undefined) updateData.price = input.price;
    if (input.condition !== undefined) updateData.condition = input.condition;
    if (input.status !== undefined) updateData.status = input.status;
    if (input.categoryId !== undefined) updateData.category = { connect: { id: input.categoryId } };
    if (input.quantity !== undefined) updateData.quantity = input.quantity;

    const updated = await this.productRepository.update(input.productId, updateData);
    if (updated.isLeft()) return left(updated.value);

    return right({
      id: updated.value.id,
      title: updated.value.title,
      description: updated.value.description,
      price: updated.value.price,
      condition: updated.value.condition as 'NEW' | 'USED',
      categoryId: updated.value.categoryId!,
      sellerId: updated.value.sellerId!,
      status: updated.value.status,
      quantity: updated.value.quantity,
      soldCount: updated.value.soldCount,
      createdAt: updated.value.createdAt,
    });
  }
}
