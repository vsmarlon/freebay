import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { CartRepository } from '../domain/repositories/cart.repository';

@Injectable()
export class ClearCartUseCase {
  constructor(private readonly cartRepository: CartRepository) {}

  async execute(userId: string): Promise<Either<AppError, { cleared: boolean }>> {
    const result = await this.cartRepository.clear(userId);
    if (isLeft(result)) return left(result.value);

    return right({ cleared: true });
  }
}
