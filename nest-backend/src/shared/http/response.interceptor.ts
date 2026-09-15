import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { AppError, InternalServerError } from '@/shared/core/errors';
import { Left, Right } from '@/shared/core/either';

@Injectable()
export class EitherInterceptor<T> implements NestInterceptor<T, T> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<T> {
    return new Observable<T>((subscriber) => {
      next.handle().subscribe({
        next: (value) => {
          if (value instanceof Left) {
            const error = value.value;
            if (error instanceof AppError) {
              subscriber.error(error);
            } else {
              subscriber.error(new InternalServerError());
            }
            return;
          }
          if (value instanceof Right) {
            subscriber.next(value.value as T);
            return;
          }
          subscriber.next(value as T);
        },
        error: (err) => subscriber.error(err),
        complete: () => subscriber.complete(),
      });
    });
  }
}
