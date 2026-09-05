import { Logger } from '@nestjs/common';
import { PrismaService } from './prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError, DatabaseError } from '@/shared/core/errors';

export abstract class BasePrismaRepository {
  protected readonly logger = new Logger(this.constructor.name);

  constructor(protected readonly prisma: PrismaService) {}

  protected async safeRun<T>(operation: () => Promise<T>, errorMessage = 'Erro no banco de dados'): RepositoryResponse<T> {
    try {
      const result = await operation();
      return right(result);
    } catch (error) {
      if (error instanceof AppError) return left(error);
      this.logger.error(errorMessage, error instanceof Error ? error.stack : error);
      return left(new DatabaseError(errorMessage));
    }
  }
}
