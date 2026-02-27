import { IProductRepository } from '@/domain/repositories';
import { Either, right, left } from '@/domain/either';
import { AppError, NotFoundError } from '@/domain/errors';

export class DeleteProductUseCase {
  constructor(private productRepository: IProductRepository) {}

  async execute(id: string): Promise<Either<AppError, void>> {
    const product = await this.productRepository.findById(id);
    if (!product) {
      return left(new NotFoundError('Produto'));
    }

    await this.productRepository.softDelete(id);
    return right(undefined);
  }
}
