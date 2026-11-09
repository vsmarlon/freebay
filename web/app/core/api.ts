export type ApiRequestOptions = {
  auth?: boolean;
  signal?: AbortSignal;
  headers?: HeadersInit;
  retryAfterRefresh?: boolean;
};
export class ApiError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly code?: string,
    public readonly details?: unknown,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}
// ponytail: endpoint contracts are owned by the backend; keep their single trust-boundary cast here.
function backendValue<T>(value: unknown): T {
  return value as T;
}
let accessToken: string | null = null;
let tokenFlight: Promise<string> | null = null;
let refreshFlight: Promise<string> | null = null;
let generation = 0;
let accessExpiry = 0;
const expiryOf = (token: string) => {
  try {
    const segment = token.split('.')[1];
    if (!segment) return 0;
    const claims: unknown = JSON.parse(atob(segment.replace(/-/g, '+').replace(/_/g, '/')));
    return claims && typeof claims === 'object' && 'exp' in claims && typeof claims.exp === 'number'
      ? claims.exp * 1000
      : 0;
  } catch {
    return 0;
  }
};
const allowedPath = (path: string) =>
  path.startsWith('/') &&
  !path.startsWith('//') &&
  !path.startsWith('/\\') &&
  new URL(path, location.origin).origin === location.origin;
async function requestToken(): Promise<string> {
  const response = await fetch('/auth/web/session/access-token', {
    method: 'POST',
    credentials: 'include',
    cache: 'no-store',
    headers: { 'X-Freebay-API': '1' },
  });
  if (!response.ok) throw new ApiError('Unable to obtain web session token', response.status);
  let payload: unknown = await response.json();
  if (payload && typeof payload === 'object' && 'data' in payload) payload = payload.data;
  if (
    !payload ||
    typeof payload !== 'object' ||
    !('token' in payload) ||
    typeof payload.token !== 'string'
  )
    throw new ApiError('Invalid web session token response', 502);
  return payload.token;
}
async function getToken(force = false): Promise<string> {
  if (!force && accessToken && (!accessExpiry || accessExpiry > Date.now() + 30000))
    return accessToken;
  if (!tokenFlight) {
    const before = generation;
    const flight = requestToken()
      .catch((error: unknown) => {
        if (error instanceof ApiError && error.status === 401) return refreshToken();
        throw error;
      })
      .then((token) => {
        if (before !== generation) throw new ApiError('Session changed during token request', 401);
        accessToken = token;
        accessExpiry = expiryOf(token);
        return token;
      })
      .finally(() => {
        if (tokenFlight === flight) tokenFlight = null;
      });
    tokenFlight = flight;
  }
  return tokenFlight;
}
async function refreshToken(): Promise<string> {
  if (!refreshFlight) {
    const before = generation;
    const refresh = async () => {
      const response = await fetch('/auth/web/session/refresh', {
        method: 'POST',
        credentials: 'include',
        cache: 'no-store',
        headers: { 'X-Freebay-API': '1' },
      });
      if (!response.ok) throw new ApiError('Web session refresh failed', response.status);
      const token = await requestToken();
      if (before !== generation) throw new ApiError('Session changed during refresh', 401);
      accessToken = token;
      accessExpiry = expiryOf(token);
      return token;
    };
    const lockedRefresh = async () => {
      let token = '';
      await navigator.locks.request('freebay.web-session-refresh', async () => {
        token = await refresh();
      });
      return token;
    };
    const flight = (
      typeof navigator !== 'undefined' && navigator.locks ? lockedRefresh() : refresh()
    ).finally(() => {
      if (refreshFlight === flight) refreshFlight = null;
    });
    refreshFlight = flight;
  }
  return refreshFlight;
}
export function clearAccessToken() {
  generation++;
  accessToken = null;
  accessExpiry = 0;
  tokenFlight = null;
  refreshFlight = null;
}
export const accessTokenForSocket = () => getToken();
export async function refreshAccessToken(): Promise<void> {
  await refreshToken();
}
async function send<T>(
  method: string,
  path: string,
  body: unknown,
  options: ApiRequestOptions = {},
  asBlob = false,
): Promise<T> {
  if (typeof window === 'undefined')
    throw new Error('Browser API client is unavailable during server rendering');
  const requestGeneration = generation;
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
  if (requestGeneration !== generation) throw new ApiError('Session changed during request', 401);
  if (response.status === 401 && auth && !write && options.retryAfterRefresh !== false)
    response = await execute(await refreshToken());
  if (requestGeneration !== generation) throw new ApiError('Session changed during request', 401);
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
    if (requestGeneration !== generation) throw new ApiError('Session changed during request', 401);
    return backendValue<T>(result);
  }
  const text = await response.text();
  if (requestGeneration !== generation) throw new ApiError('Session changed during request', 401);
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
export const api = {
  get: <T>(path: string, options?: ApiRequestOptions) => send<T>('GET', path, undefined, options),
  post: <T>(path: string, body?: unknown, options?: ApiRequestOptions) =>
    send<T>('POST', path, body, options),
  patch: <T>(path: string, body?: unknown, options?: ApiRequestOptions) =>
    send<T>('PATCH', path, body, options),
  delete: <T>(path: string, options?: ApiRequestOptions) =>
    send<T>('DELETE', path, undefined, options),
  blob: (path: string, options?: ApiRequestOptions) =>
    send<Blob>('GET', path, undefined, options, true),
};
