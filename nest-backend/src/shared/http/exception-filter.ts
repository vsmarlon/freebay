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

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let code = 'INTERNAL_SERVER_ERROR';
    let message = 'Erro interno do servidor';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      
      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const responseObj = exceptionResponse as {
          code?: string;
          message?: string | string[];
          error?: { code?: string; message?: string | string[] };
        };
        const nestedError = responseObj.error;
        const resolvedMessage = nestedError?.message ?? responseObj.message;

        code = nestedError?.code || responseObj.code || exception.name;
        message = Array.isArray(resolvedMessage)
          ? resolvedMessage[0] || exception.message
          : resolvedMessage || exception.message;
      } else {
        message = exception.message;
      }
    } else if (exception instanceof AppError) {
      status = exception.statusCode;
      code = exception.code;
      message = exception.message;
    } else if (exception instanceof Error) {
      message = exception.message;
      this.logger.error(`Unhandled exception: ${exception.message}`, exception.stack);
    }

    response.status(status).json({
      success: false,
      error: {
        code,
        message,
      },
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
