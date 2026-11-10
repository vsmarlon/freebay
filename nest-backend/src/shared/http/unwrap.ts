import { Either } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

export function unwrap<T>(result: Either<AppError, T>): T {
  if (result.isLeft()) throw result.value;
  return result.value;
}
