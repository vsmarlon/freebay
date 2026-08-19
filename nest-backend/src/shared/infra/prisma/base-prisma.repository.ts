import { PrismaService } from './prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

export abstract class BasePrismaRepository {
  constructor(protected readonly prisma: PrismaService) {}

  protected async safeRun<T>(operation: () => Promise<T>, errorMessage = 'Erro no banco de dados'): RepositoryResponse<T> {
    try {
      const result = await operation();
      return right(result);
    } catch (error) {
      if (error instanceof AppError) return left(error);
      return left(new AppError('DB_ERROR', errorMessage));
    }
  }
}
