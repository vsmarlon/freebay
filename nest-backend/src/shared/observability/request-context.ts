import { AsyncLocalStorage } from 'node:async_hooks';
import { randomUUID } from 'node:crypto';
import { NextFunction, Request, Response } from 'express';

export const REQUEST_ID_HEADER = 'x-request-id';

export interface RequestContext {
  requestId: string;
  userId?: string;
}

const storage = new AsyncLocalStorage<RequestContext>();

export function getRequestContext(): RequestContext | undefined {
  return storage.getStore();
}

export function getRequestId(): string | undefined {
  return storage.getStore()?.requestId;
}

export function setContextUserId(userId: string): void {
  const store = storage.getStore();
  if (store) store.userId = userId;
}

export function runWithRequestContext<T>(context: RequestContext, callback: () => T): T {
  return storage.run(context, callback);
}

function normalizeInboundId(value: unknown): string | null {
  const raw = Array.isArray(value) ? value[0] : value;
  if (typeof raw !== 'string') return null;
  const trimmed = raw.trim();
  if (!trimmed || trimmed.length > 200 || !/^[A-Za-z0-9._:-]+$/.test(trimmed)) return null;
  return trimmed;
}

export function requestContextMiddleware(
  request: Request,
  response: Response,
  next: NextFunction,
): void {
  const requestId = normalizeInboundId(request.headers[REQUEST_ID_HEADER]) ?? randomUUID();
  response.setHeader(REQUEST_ID_HEADER, requestId);
  runWithRequestContext({ requestId }, () => next());
}
