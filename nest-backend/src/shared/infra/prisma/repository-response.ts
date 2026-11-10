import { Logger } from '@nestjs/common';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError, DatabaseError } from '@/shared/core/errors';

export async function repositoryResponse<T>(
  operation: () => Promise<T>,
  errorMessage = 'Erro no banco de dados',
  context = 'PrismaRepository',
): RepositoryResponse<T> {
  try {
    return right(await operation());
  } catch (error: unknown) {
    if (error instanceof AppError) return left(error);
    Logger.error(errorMessage, error instanceof Error ? error.stack : String(error), context);
    return left(new DatabaseError(errorMessage));
  }
}
