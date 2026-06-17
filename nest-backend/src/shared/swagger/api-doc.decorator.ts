import { applyDecorators, HttpStatus, Type } from '@nestjs/common';
import {
  ApiOperation,
  ApiBody,
  ApiBearerAuth,
  ApiOkResponse,
  ApiCreatedResponse,
  ApiBadRequestResponse,
  ApiUnauthorizedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiConflictResponse,
  ApiParam,
  ApiQuery,
  ApiUnprocessableEntityResponse,
  ApiTooManyRequestsResponse,
  ApiGoneResponse,
} from '@nestjs/swagger';
import { ApiErrorResponse } from './api-response.class';

export interface ApiParamOptions {
  name: string;
  description?: string;
}

export interface ApiQueryOptions {
  name: string;
  description?: string;
  required?: boolean;
}

export interface ApiErrorOption {
  status: number;
  description?: string;
}

export interface ApiDocOptions {
  summary: string;
  description?: string;
  bodyType?: Type<unknown>;
  responseType?: Type<unknown>;
  responseStatus?: number;
  auth?: boolean;
  params?: ApiParamOptions[];
  queries?: ApiQueryOptions[];
  errors?: ApiErrorOption[];
}

export function ApiDoc(options: ApiDocOptions): MethodDecorator {
  const decorators: (ClassDecorator | MethodDecorator | PropertyDecorator)[] = [];

  decorators.push(ApiOperation({ summary: options.summary, description: options.description }));

  if (options.bodyType) {
    decorators.push(ApiBody({ type: options.bodyType }));
  }

  if (options.responseType) {
    const status = options.responseStatus ?? HttpStatus.OK;
    const responseDecorator =
      status === HttpStatus.CREATED
        ? ApiCreatedResponse({ description: options.summary, type: options.responseType })
        : ApiOkResponse({ description: options.summary, type: options.responseType });
    decorators.push(responseDecorator);
  }

  if (options.auth) {
    decorators.push(ApiBearerAuth());
    decorators.push(ApiUnauthorizedResponse({ description: 'Unauthorized', type: ApiErrorResponse }));
  }

  if (options.params) {
    for (const p of options.params) {
      decorators.push(ApiParam({ name: p.name, description: p.description }));
    }
  }

  if (options.queries) {
    for (const q of options.queries) {
      decorators.push(ApiQuery({ name: q.name, description: q.description, required: q.required ?? false }));
    }
  }

  decorators.push(ApiBadRequestResponse({ description: 'Validation error', type: ApiErrorResponse }));

  if (options.errors) {
    for (const err of options.errors) {
      switch (err.status) {
        case 401:
          break;
        case 403:
          decorators.push(ApiForbiddenResponse({ description: err.description ?? 'Forbidden', type: ApiErrorResponse }));
          break;
        case 404:
          decorators.push(ApiNotFoundResponse({ description: err.description ?? 'Not found', type: ApiErrorResponse }));
          break;
        case 409:
          decorators.push(ApiConflictResponse({ description: err.description ?? 'Conflict', type: ApiErrorResponse }));
          break;
        case 410:
          decorators.push(ApiGoneResponse({ description: err.description ?? 'Gone', type: ApiErrorResponse }));
          break;
        case 422:
          decorators.push(ApiUnprocessableEntityResponse({ description: err.description ?? 'Unprocessable entity', type: ApiErrorResponse }));
          break;
        case 429:
          decorators.push(ApiTooManyRequestsResponse({ description: err.description ?? 'Too many requests', type: ApiErrorResponse }));
          break;
      }
    }
  }

  return applyDecorators(...decorators);
}
