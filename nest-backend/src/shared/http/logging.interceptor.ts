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
  private readonly sensitiveKeys = new Set([
    'password',
    'newPassword',
    'token',
    'refreshToken',
    'authorization',
    'code',
  ]);

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest();
    const { method, url, body, headers } = request;
    const now = Date.now();

    this.logger.log(`[REQUEST] ${method} ${url}`);
    if (headers?.authorization) {
      this.logger.debug('[AUTH_HEADER] [REDACTED]');
    }
    if (body && Object.keys(body).length > 0) {
      this.logger.debug(`[BODY] ${JSON.stringify(this.redact(body))}`);
    }

    return next.handle().pipe(
      tap({
        next: (data) => {
          const responseTime = Date.now() - now;
          this.logger.log(`[RESPONSE] ${method} ${url} - ${responseTime}ms`);
          if (data && typeof data === 'object' && 'data' in data) {
            const responseData = (data as { data: unknown }).data;
            if (responseData !== undefined && responseData !== null) {
              const dataStr = JSON.stringify(this.redact(responseData));
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

  private redact(value: unknown): unknown {
    if (Array.isArray(value)) {
      return value.map((item) => this.redact(item));
    }

    if (!value || typeof value !== 'object') {
      return value;
    }

    return Object.fromEntries(
      Object.entries(value).map(([key, nestedValue]) => [
        key,
        this.sensitiveKeys.has(key) ? '[REDACTED]' : this.redact(nestedValue),
      ]),
    );
  }
}
