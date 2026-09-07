import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { setContextUserId } from '../observability/request-context';
import { JsonValue, redact } from '../utils/redact.util';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  private readonly isDebug =
    process.env.NODE_ENV !== 'production' && process.env.LOG_DEBUG === 'true';

  intercept(context: ExecutionContext, next: CallHandler): Observable<JsonValue | void> {
    const httpContext = context.switchToHttp();
    const request = httpContext.getRequest();
    const response = httpContext.getResponse();
    const { method, url, body, headers, user } = request;
    const now = Date.now();

    if (user?.userId) {
      setContextUserId(user.userId);
    }

    if (this.isDebug) {
      if (headers?.authorization) {
        this.logger.debug('[AUTH_HEADER] [REDACTED]');
      }
      if (body && Object.keys(body).length > 0) {
        this.logger.debug(`[BODY] ${JSON.stringify(redact(body))}`);
      }
    }

    return next.handle().pipe(
      tap({
        next: (data) => {
          const responseTime = Date.now() - now;
          this.logger.log(
            `${method} ${url} ${response?.statusCode ?? ''} - ${responseTime}ms`,
          );
          if (this.isDebug && data && typeof data === 'object' && 'data' in data) {
            const responseData = (data as { data: JsonValue }).data;
            if (responseData !== undefined && responseData !== null) {
              const dataStr = JSON.stringify(redact(responseData));
              this.logger.debug(
                dataStr.length <= 1000
                  ? `[RESPONSE_DATA] ${dataStr}`
                  : `[RESPONSE_DATA] ${dataStr.substring(0, 1000)}... (truncated)`,
              );
            }
          }
        },
        error: (error) => {
          const responseTime = Date.now() - now;
          this.logger.error(`${method} ${url} - ${responseTime}ms - ${error.message}`);
        },
      }),
    );
  }
}
