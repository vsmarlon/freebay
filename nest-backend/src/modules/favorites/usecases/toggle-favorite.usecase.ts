import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, ForbiddenError } from '@/shared/core/errors';
import { FavoriteDatabaseRepository } from '../data/repositories/favorite-database.repository';

@Injectable()
export class ToggleFavoriteUseCase {
  constructor(private readonly favoriteRepository: FavoriteDatabaseRepository) {}

  async execute(userId: string, productId: string): Promise<Either<AppError, void>> {
    const productResult = await this.favoriteRepository.findProductById(productId);
    if (productResult.isLeft()) {
      return left(productResult.value);
    }
    if (!productResult.value || productResult.value.status !== 'ACTIVE') {
      return left(new NotFoundError('Produto'));
    }

    if (productResult.value.sellerId === userId) {
      return left(new ForbiddenError('Você não pode favoritar seu próprio produto'));
    }

    const existingResult = await this.favoriteRepository.findByUserAndProduct(userId, productId);
    if (existingResult.isLeft()) {
      return left(existingResult.value);
    }

    if (existingResult.value) {
      const deleteResult = await this.favoriteRepository.delete(userId, productId);
      if (deleteResult.isLeft()) {
        return left(deleteResult.value);
      }
      return right(undefined);
    }

    const createResult = await this.favoriteRepository.create(userId, productId);
    if (createResult.isLeft()) {
      return left(createResult.value);
    }

    return right(undefined);
  }
}
