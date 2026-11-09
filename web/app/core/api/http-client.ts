import { allowedPath } from './allowed-path';
import { ApiError } from './api-error';
import { currentGeneration, getToken, refreshToken } from './session-token';

export type ApiRequestOptions = {
  auth?: boolean;
  signal?: AbortSignal;
  headers?: HeadersInit;
  retryAfterRefresh?: boolean;
};

// ponytail: endpoint contracts are owned by the backend; keep their single trust-boundary cast here.
function backendValue<T>(value: unknown): T {
  return value as T;
}

export async function send<T>(
  method: string,
  path: string,
  body: unknown,
  options: ApiRequestOptions = {},
  asBlob = false,
): Promise<T> {
  if (typeof window === 'undefined')
    throw new Error('Browser API client is unavailable during server rendering');
  const requestGeneration = currentGeneration();
  if (!allowedPath(path)) throw new TypeError('API requests must use a same-origin absolute path');
  const auth = options.auth !== false,
    write = !['GET', 'HEAD', 'OPTIONS'].includes(method),
    headers = new Headers(options.headers);
  if (body !== undefined && !(body instanceof FormData))
    headers.set('Content-Type', 'application/json');
  const execute = (token?: string) => {
    const requestHeaders = new Headers(headers);
    requestHeaders.set('X-Freebay-API', '1');
    if (token) requestHeaders.set('Authorization', `Bearer ${token}`);
    return fetch(path, {
      method,
      credentials: 'include',
      signal: options.signal,
      headers: requestHeaders,
      body:
        body === undefined
          ? undefined
          : body instanceof FormData || typeof body === 'string'
            ? body
            : JSON.stringify(body),
      cache: 'no-store',
    });
  };
  let response = await execute(auth ? await getToken(write) : undefined);
  if (requestGeneration !== currentGeneration())
    throw new ApiError('Session changed during request', 401);
  if (response.status === 401 && auth && !write && options.retryAfterRefresh !== false)
    response = await execute(await refreshToken());
  if (requestGeneration !== currentGeneration())
    throw new ApiError('Session changed during request', 401);
  if (!response.ok) {
    let errorBody: unknown;
    try {
      errorBody = await response.json();
    } catch {
      errorBody = undefined;
    }
    const envelope = errorBody && typeof errorBody === 'object' ? errorBody : {};
    const obj =
      'error' in envelope && envelope.error && typeof envelope.error === 'object'
        ? envelope.error
        : envelope;
    const code = 'code' in obj && typeof obj.code === 'string' ? obj.code : undefined;
    const rawMessage = 'message' in obj ? obj.message : response.statusText;
    const message = Array.isArray(rawMessage)
      ? String(rawMessage[0] ?? response.statusText)
      : typeof rawMessage === 'string'
        ? rawMessage
        : response.statusText;
    throw new ApiError(message, response.status, code, errorBody);
  }
  if (response.status === 204) return backendValue<T>(undefined);
  if (asBlob) {
    const result = await response.blob();
    if (requestGeneration !== currentGeneration())
      throw new ApiError('Session changed during request', 401);
    return backendValue<T>(result);
  }
  const text = await response.text();
  if (requestGeneration !== currentGeneration())
    throw new ApiError('Session changed during request', 401);
  if (!text) return backendValue<T>(undefined);
  let payload: unknown;
  try {
    payload = JSON.parse(text);
  } catch {
    throw new ApiError('Invalid API response', 502);
  }
  if (payload && typeof payload === 'object' && 'data' in payload)
    return backendValue<T>(payload.data);
  return backendValue<T>(payload);
}
