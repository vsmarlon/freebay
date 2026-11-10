import { ExecutionContext } from '@nestjs/common';
import { Prisma } from '@prisma/client';

export interface HttpContextParts<TRequest, TResponse = unknown> {
  request: TRequest;
  response?: TResponse;
}

// The single sanctioned assertion in the codebase. Nest's ExecutionContext
// declares generic members whose type parameters default to the permissive
// top type (getArgs, getArgByIndex), which no concrete object can satisfy without
// unsafe generics, so a faithful implementation is not expressible. Building
// it here once keeps every spec's own code assertion-free; use this helper
// rather than shaping an ExecutionContext inline.
export function createExecutionContext<TRequest, TResponse = unknown>(
  parts: HttpContextParts<TRequest, TResponse>,
): ExecutionContext {
  const handler = function testHandler() {};
  class TestController {}

  const context = {
    switchToHttp: () => ({
      getRequest: () => parts.request,
      getResponse: () => parts.response,
      getNext: () => undefined,
    }),
    switchToRpc: () => ({
      getData: () => parts.request,
      getContext: () => parts.request,
    }),
    switchToWs: () => ({
      getClient: () => parts.request,
      getData: () => parts.request,
      getPattern: () => '',
    }),
    getArgs: () => [parts.request, parts.response],
    getArgByIndex: (index: number) => [parts.request, parts.response][index],
    getType: () => 'http',
    getHandler: () => handler,
    getClass: () => TestController,
  };

  return context as ExecutionContext;
}

// Same rationale as createExecutionContext: Prisma.TransactionClient is a union
// of fully generic delegates that no hand-built object can satisfy, so a test
// double for it needs one assertion. It lives here rather than in each spec.
export function createTransactionClient<T extends object>(
  delegates: T,
): Prisma.TransactionClient & T {
  return delegates as Prisma.TransactionClient & T;
}
