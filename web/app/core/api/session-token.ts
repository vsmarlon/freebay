import { ApiError } from './api-error';

let accessToken: string | null = null;
let tokenFlight: Promise<string> | null = null;
let refreshFlight: Promise<string> | null = null;
let generation = 0;
let accessExpiry = 0;

export const currentGeneration = () => generation;

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

export async function getToken(force = false): Promise<string> {
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

export async function refreshToken(): Promise<string> {
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
