import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { AppError } from '../core/errors';
import { REQUEST_ID_HEADER, getRequestId } from '../observability/request-context';
import { captureError } from '../observability/sentry';
import { redact } from '../utils/redact.util';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const requestId = getRequestId();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let code = 'INTERNAL_SERVER_ERROR';
    let message = 'Erro interno do servidor';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const responseObj = exceptionResponse as Record<string, unknown>;

        if (responseObj.errors) {
          const validationErrors = responseObj.errors as Array<{
            property: string;
            value: unknown;
            constraints: Record<string, string>;
          }>;
          const details = validationErrors.map((e) => ({
            field: e.property,
            constraints: e.constraints,
          }));
          this.logger.warn(
            `[VALIDATION] ${request.method} ${request.url} - ${JSON.stringify(redact(details))}`,
          );
        }

        const nestedError = responseObj.error as { code?: string; message?: string } | undefined;
        const resolvedMessage = nestedError?.message ?? responseObj.message;

        code = (nestedError?.code as string) || (responseObj.code as string) || exception.name;
        message = Array.isArray(resolvedMessage)
          ? (resolvedMessage as string[])[0] || exception.message
          : (resolvedMessage as string) || exception.message;
      } else {
        message = exception.message;
        this.logger.warn(`[HTTP] ${request.method} ${request.url} - ${status} ${message}`);
      }

      if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
        captureError(exception, { requestId, path: request.url, code });
      }
    } else if (exception instanceof AppError) {
      status = exception.statusCode;
      code = exception.code;
      message = exception.message;
      this.logger.warn(`[APP] ${request.method} ${request.url} - ${code}: ${message}`);
      if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
        captureError(exception, { requestId, path: request.url, code });
      }
    } else if (exception instanceof Error) {
      message = exception.message;
      this.logger.error(
        `[UNHANDLED] ${request.method} ${request.url} - ${exception.message}`,
        exception.stack,
      );
      captureError(exception, { requestId, path: request.url, code });
    } else {
      this.logger.error(
        `[UNKNOWN] ${request.method} ${request.url} - non-Error thrown: ${JSON.stringify(redact(exception))}`,
      );
      captureError(exception, { requestId, path: request.url, code });
    }

    if (requestId) {
      response.setHeader(REQUEST_ID_HEADER, requestId);
    }

    response.status(status).json({
      success: false,
      error: {
        code,
        message,
      },
      requestId: requestId ?? null,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
