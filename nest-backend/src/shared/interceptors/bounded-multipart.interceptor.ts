import {
  BadRequestException,
  CallHandler,
  ExecutionContext,
  Logger,
  mixin,
  NestInterceptor,
  PayloadTooLargeException,
  Type,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { NextFunction } from 'express-serve-static-core';
import multer, { memoryStorage, MulterError } from 'multer';
import { Readable } from 'node:stream';
import { Observable, from } from 'rxjs';
import { switchMap } from 'rxjs/operators';

const MAX_MULTIPART_FIELDS = 64;
const MAX_MULTIPART_PARTS = 68;
const MAX_MULTIPART_FIELD_BYTES = 4 * 1024;
const RAW_CHUNK_BYTES = 64 * 1024;
const transportLogger = new Logger('BoundedMultipartInterceptor');

function retainTransportErrorsUntilClose(request: Request): void {
  const onError = (error: Error) => {
    const code = 'code' in error && typeof error.code === 'string' ? error.code : 'unknown';
    if (code !== 'ECONNRESET' && code !== 'ERR_STREAM_PREMATURE_CLOSE') {
      transportLogger.warn(`Multipart request stream error (${code})`);
    }
  };
  const onClose = () => {
    request.removeListener('error', onError);
    request.removeListener('close', onClose);
  };
  request.on('error', onError);
  request.once('close', onClose);
}

function drainRejectedRequest(request: Request): void {
  retainTransportErrorsUntilClose(request);
  request.resume();
}

function makeReplayRequest(request: Request, chunks: Buffer[]): Request {
  // ponytail: Multer needs a stream plus these HTTP properties; this narrow cast bridges Express's full request declaration.
  return Object.assign(Readable.from(chunks, { objectMode: false }), {
    headers: request.headers,
    method: request.method,
    url: request.url,
  }) as Request;
}

export function BoundedMultipartInterceptor(
  fieldName: string,
  maxFiles: number,
  maxBytes = 20 * 1024 * 1024,
  fieldSizeBytes = MAX_MULTIPART_FIELD_BYTES,
  fileSizeBytes = maxBytes,
): Type<NestInterceptor> {
  class BoundedMultipartMixin implements NestInterceptor {
    private readonly parse = multer({
      storage: memoryStorage(),
      limits: {
        files: maxFiles,
        fileSize: fileSizeBytes,
        fields: MAX_MULTIPART_FIELDS,
        parts: MAX_MULTIPART_PARTS,
        fieldSize: fieldSizeBytes,
        fieldNameSize: 100,
      },
    })[maxFiles === 1 ? 'single' : 'array'](fieldName, ...(maxFiles === 1 ? [] : [maxFiles]));

    intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
      const request = context.switchToHttp().getRequest<Request>();
      if (!request.is('multipart/form-data')) return next.handle();
      return from(this.collectAndParse(request, context.switchToHttp().getResponse<Response>())).pipe(switchMap(() => next.handle()));
    }

    private async collectAndParse(request: Request, response: Response): Promise<void> {
      const declared = request.headers['content-length'];
      if (declared && Number(declared) > maxBytes) {
        drainRejectedRequest(request);
        throw new PayloadTooLargeException(`Multipart request exceeds ${maxBytes} bytes`);
      }

      // ponytail: fixed 64 KiB raw slabs plus replayed Multer buffers stay under roughly 2x the route cap.
      const chunks: Buffer[] = [];
      let total = 0;
      let current: Buffer | undefined;
      let currentLength = 0;
      await new Promise<void>((resolve, reject) => {
        const cleanup = (removeError = true) => {
          request.removeListener('data', onData);
          request.removeListener('end', onEnd);
          if (removeError) request.removeListener('error', onError);
          request.removeListener('aborted', onAborted);
        };
        const onError = (error: Error) => { cleanup(); chunks.length = 0; reject(error); };
        const onAborted = () => {
          retainTransportErrorsUntilClose(request);
          cleanup(false);
          chunks.length = 0;
          reject(new BadRequestException('Multipart request was aborted'));
        };
        const onData = (chunk: Buffer | string) => {
          const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
          if (buffer.length > maxBytes - total) {
            cleanup(false);
            chunks.length = 0;
            request.removeListener('error', onError);
            drainRejectedRequest(request);
            reject(new PayloadTooLargeException(`Multipart request exceeds ${maxBytes} bytes`));
            return;
          }
          total += buffer.length;
          let offset = 0;
          while (offset < buffer.length) {
            if (!current || currentLength === current.length) {
              current = Buffer.allocUnsafe(Math.min(RAW_CHUNK_BYTES, maxBytes - (total - buffer.length + offset)));
              chunks.push(current);
              currentLength = 0;
            }
            const copied = Math.min(current.length - currentLength, buffer.length - offset);
            buffer.copy(current, currentLength, offset, offset + copied);
            currentLength += copied;
            offset += copied;
          }
        };
        const onEnd = () => {
          cleanup();
          if (current && currentLength < current.length) chunks[chunks.length - 1] = current.subarray(0, currentLength);
          resolve();
        };
        request.on('data', onData);
        request.once('end', onEnd);
        request.once('error', onError);
        request.once('aborted', onAborted);
      });

      const replayRequest = makeReplayRequest(request, chunks);
      await new Promise<void>((resolve, reject) => {
        this.parse(replayRequest, response, ((error?: Error | 'route' | 'router') => {
          if (error instanceof MulterError) {
            reject(error.code === 'LIMIT_FILE_SIZE'
              ? new PayloadTooLargeException(error.message)
              : new BadRequestException(error.message));
          } else if (error) reject(new BadRequestException(error instanceof Error ? error.message : 'Multipart parser rejected the request'));
          else {
            request.body = replayRequest.body;
            request.file = replayRequest.file;
            request.files = replayRequest.files;
            resolve();
          }
        }) satisfies NextFunction);
      });
    }
  }

  return mixin(BoundedMultipartMixin);
}
