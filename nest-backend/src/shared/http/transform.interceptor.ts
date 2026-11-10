import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  StreamableFile,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface Response<T> {
  success: boolean;
  data: T;
}

@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, Response<T> | StreamableFile>
{
  intercept(
    _context: ExecutionContext,
    next: CallHandler<T | StreamableFile>,
  ): Observable<Response<T> | StreamableFile> {
    return next.handle().pipe(
      map((data) =>
        data instanceof StreamableFile ? data : { success: true, data },
      ),
    );
  }
}
