import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { AppError, InternalServerError } from '@/shared/core/errors';

@Injectable()
export class EitherInterceptor<T> implements NestInterceptor<T, T> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<T> {
    return new Observable<T>((subscriber) => {
      next.handle().subscribe({
        next: (value) => {
          if (value && typeof value === 'object' && '_tag' in value) {
            const either = value as EitherShape;
            if (either._tag === 'left') {
              const error = either.value;
              if (error instanceof AppError) {
                subscriber.error(error);
              } else {
                subscriber.error(new InternalServerError());
              }
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

interface EitherShape {
  _tag: 'left' | 'right';
  value: { code?: string; message?: string } | AppError | Record<string, string | number | boolean | null | object | undefined> | string | number | boolean | null | undefined;
}
