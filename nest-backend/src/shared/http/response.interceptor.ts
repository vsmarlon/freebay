import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { AppError } from '@/shared/core/errors';

@Injectable()
export class EitherInterceptor<T> implements NestInterceptor<T, T> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<T> {
    return new Observable<T>((subscriber) => {
      next.handle().subscribe({
        next: (value) => {
          if (value && typeof value === 'object' && '_tag' in value) {
            const either = value as { _tag: string; value: unknown };
            if (either._tag === 'left') {
              const error = either.value as { code: string; message: string };
              subscriber.error(new AppError(error.code, error.message));
              return;
            }
            subscriber.next(either.value as T);
          } else {
            subscriber.next(value as T);
          }
        },
        error: (err) => subscriber.error(err),
        complete: () => subscriber.complete(),
      });
    });
  }
}
