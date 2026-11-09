import { send, type ApiRequestOptions } from './http-client';

export const api = {
  get: <T>(path: string, options?: ApiRequestOptions<T>) =>
    send<T>('GET', path, undefined, options),
  post: <T>(path: string, body?: unknown, options?: ApiRequestOptions<T>) =>
    send<T>('POST', path, body, options),
  patch: <T>(path: string, body?: unknown, options?: ApiRequestOptions<T>) =>
    send<T>('PATCH', path, body, options),
  delete: <T>(path: string, options?: ApiRequestOptions<T>) =>
    send<T>('DELETE', path, undefined, options),
  blob: (path: string, options?: ApiRequestOptions<Blob>) =>
    send<Blob>('GET', path, undefined, options, true),
};
