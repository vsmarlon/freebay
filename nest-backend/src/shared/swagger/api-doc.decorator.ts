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
  type?: string | Type<unknown>;
}

export interface ApiQueryOptions {
  name: string;
  description?: string;
  required?: boolean;
  type?: string | Type<unknown>;
}

export interface ApiErrorOption {
  status: number;
  description?: string;
}

export interface ApiDocOptions {
  summary?: string;
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

  if (options.summary || options.description) {
    decorators.push(ApiOperation({ summary: options.summary, description: options.description }));
  }

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
    decorators.push(ApiBearerAuth('bearer'));
    decorators.push(ApiUnauthorizedResponse({ description: 'Sessão inválida ou expirada', type: ApiErrorResponse }));
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

  if (options.errors) {
    for (const err of options.errors) {
      switch (err.status) {
        case 400:
          decorators.push(ApiBadRequestResponse({ description: err.description ?? 'Requisição inválida', type: ApiErrorResponse }));
          break;
        case 403:
          decorators.push(ApiForbiddenResponse({ description: err.description ?? 'Acesso proibido', type: ApiErrorResponse }));
          break;
        case 404:
          decorators.push(ApiNotFoundResponse({ description: err.description ?? 'Recurso não encontrado', type: ApiErrorResponse }));
          break;
        case 409:
          decorators.push(ApiConflictResponse({ description: err.description ?? 'Conflito de estado', type: ApiErrorResponse }));
          break;
        case 410:
          decorators.push(ApiGoneResponse({ description: err.description ?? 'Recurso expirado', type: ApiErrorResponse }));
          break;
        case 422:
          decorators.push(ApiUnprocessableEntityResponse({ description: err.description ?? 'Erro de validação de negócio', type: ApiErrorResponse }));
          break;
        case 429:
          decorators.push(ApiTooManyRequestsResponse({ description: err.description ?? 'Muitas requisições', type: ApiErrorResponse }));
          break;
      }
    }
  }

  return applyDecorators(...decorators);
}
