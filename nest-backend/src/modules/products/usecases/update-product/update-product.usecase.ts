import { Injectable } from '@nestjs/common';
import { ProductStatus } from '@prisma/client';
import { Either, left, right } from '@/shared/core/either';
import { AppError, ConflictError, NotFoundError, ForbiddenError, BadRequestError } from '@/shared/core/errors';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { UpdateProductInput, UpdateProductOutput } from '../../dtos/product.dto';
import {
  canEditProduct,
  canResumeProduct,
  canSetQuantity,
  resumeData,
  sellerPauseData,
} from '../../domain/product-state';

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

    if (!canEditProduct(product.value)) {
      return left(new BadRequestError('O anúncio está reservado por um pedido em aberto'));
    }

    if (input.quantity !== undefined && !canSetQuantity(input.quantity, product.value.soldCount)) {
      return left(new BadRequestError('A quantidade não pode ficar abaixo do total já vendido'));
    }

    const fieldData: Record<string, unknown> = {};
    if (input.title !== undefined) fieldData.title = input.title;
    if (input.description !== undefined) fieldData.description = input.description;
    if (input.price !== undefined) fieldData.price = input.price;
    if (input.condition !== undefined) fieldData.condition = input.condition;
    if (input.categoryId !== undefined) fieldData.category = { connect: { id: input.categoryId } };
    if (input.quantity !== undefined) fieldData.quantity = input.quantity;

    if (Object.keys(fieldData).length > 0) {
      const updated = await this.productRepository.update(input.productId, fieldData);
      if (updated.isLeft()) return left(updated.value);
    }

    if (input.status !== undefined && input.status !== product.value.status) {
      if (input.status === ProductStatus.ACTIVE) {
        if (!canResumeProduct(product.value)) {
          return left(new BadRequestError('Este anúncio não pode ser reativado pelo vendedor'));
        }
        const resumed = await this.productRepository.transitionStatus(
          input.productId,
          { status: product.value.status, pauseReason: product.value.pauseReason },
          resumeData(),
        );
        if (resumed.isLeft()) return left(resumed.value);
        if (!resumed.value) return left(new ConflictError('O anúncio mudou antes de ser reativado'));
      } else {
        const paused = await this.productRepository.transitionStatus(
          input.productId,
          { status: product.value.status, pauseReason: product.value.pauseReason },
          sellerPauseData(),
        );
        if (paused.isLeft()) return left(paused.value);
        if (!paused.value) return left(new ConflictError('O anúncio mudou antes de ser pausado'));
      }
    }

    const fresh = await this.productRepository.findById(input.productId);
    if (fresh.isLeft()) return left(fresh.value);
    if (!fresh.value) return left(new NotFoundError('Product'));

    return right({
      id: fresh.value.id,
      title: fresh.value.title,
      description: fresh.value.description,
      price: fresh.value.price,
      condition: fresh.value.condition as 'NEW' | 'USED',
      categoryId: fresh.value.categoryId!,
      sellerId: fresh.value.sellerId!,
      status: fresh.value.status,
      quantity: fresh.value.quantity,
      soldCount: fresh.value.soldCount,
      createdAt: fresh.value.createdAt,
    });
  }
}
