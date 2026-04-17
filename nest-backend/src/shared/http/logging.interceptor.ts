import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest();
    const { method, url, body } = request;
    const now = Date.now();

    this.logger.log(`[REQUEST] ${method} ${url}`);
    if (body && Object.keys(body).length > 0) {
      this.logger.debug(`[BODY] ${JSON.stringify(body)}`);
    }

    return next.handle().pipe(
      tap({
        next: (data) => {
          const responseTime = Date.now() - now;
          this.logger.log(`[RESPONSE] ${method} ${url} - ${responseTime}ms`);
          if (data && typeof data === 'object' && 'data' in data) {
            const responseData = (data as { data: unknown }).data;
            if (responseData !== undefined && responseData !== null) {
              const dataStr = JSON.stringify(responseData);
              if (dataStr.length <= 1000) {
                this.logger.debug(`[RESPONSE_DATA] ${dataStr}`);
              } else {
                this.logger.debug(`[RESPONSE_DATA] ${dataStr.substring(0, 1000)}... (truncated)`);
              }
            }
          }
        },
        error: (error) => {
          const responseTime = Date.now() - now;
          this.logger.error(`[ERROR] ${method} ${url} - ${responseTime}ms - ${error.message}`);
        },
      }),
    );
  }
}
