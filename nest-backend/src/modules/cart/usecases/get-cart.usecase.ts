import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CartRepository } from '../domain/repositories/cart.repository';

import { GetCartOutput } from '../dtos/cart.dto';

@Injectable()
export class GetCartUseCase {
  constructor(private readonly cartRepository: CartRepository) {}

  async execute(userId: string): Promise<Either<AppError, GetCartOutput>> {
    const result = await this.cartRepository.getUserCart(userId);
    if (isLeft(result)) return left(result.value);

    const items = result.value.map((item) => ({
      id: item.id,
      productId: item.productId,
      quantity: item.quantity,
      subtotal: item.quantity * item.product.price,
      product: item.product,
    }));

    return right({
      items,
      totalItems: items.reduce((acc, i) => acc + i.quantity, 0),
      totalPrice: items.reduce((acc, i) => acc + i.subtotal, 0),
    });
  }
}
