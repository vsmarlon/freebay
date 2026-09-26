import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { JwtPayload, JwtTokenType } from '@/shared/core/types';
import type { Response } from 'express';

export const WEB_ACCESS_COOKIE = 'freebay_access';
export const WEB_REFRESH_COOKIE = 'freebay_refresh';

export function getWebSessionCookie(header: string | undefined, name: string): string | undefined {
  if (!header) return undefined;

  let value: string | undefined;
  for (const part of header.split(';')) {
    const separator = part.indexOf('=');
    if (separator < 0) continue;
    const cookieName = part.slice(0, separator).trim();
    if (cookieName !== name) continue;
    if (value !== undefined) throw new UnauthorizedException('Cookie de sessão ambíguo');
    try {
      value = decodeURIComponent(part.slice(separator + 1).trim());
    } catch {
      throw new UnauthorizedException('Cookie de sessão inválido');
    }
  }
  return value;
}

export function getWebSessionCookieForTokenTypes(
  header: string | undefined,
  allowed: Array<JwtTokenType>,
): string | undefined {
  const name = allowed.includes(JwtTokenType.REFRESH) && !allowed.includes(JwtTokenType.ACCESS)
    ? WEB_REFRESH_COOKIE
    : WEB_ACCESS_COOKIE;
  return getWebSessionCookie(header, name);
}

/// Verifies a token and returns its payload only when it belongs to the
/// given user and token type. Never throws: untrusted input yields undefined.
export function ownedPayload(
  jwtService: JwtService,
  token: string | undefined,
  type: JwtTokenType,
  userId: string,
): JwtPayload | undefined {
  if (!token) return undefined;
  try {
    const payload = jwtService.verify<JwtPayload>(token);
    if (payload?.type === type && payload.userId === userId) return payload;
  } catch { void 0; }
  return undefined;
}

function sessionFlags(secure: boolean): string {
  return `HttpOnly; ${secure ? 'Secure; ' : ''}SameSite=Lax`;
}

export function setWebSessionCookies(
  response: Response,
  secure: boolean,
  access: string,
  refresh: string,
): void {
  const flags = sessionFlags(secure);
  response.setHeader('Set-Cookie', [
    `freebay_access=${encodeURIComponent(access)}; Path=/; Max-Age=900; ${flags}`,
    `freebay_refresh=${encodeURIComponent(refresh)}; Path=/auth/web/session; Max-Age=604800; ${flags}`,
  ]);
}

export function clearWebSessionCookies(
  response: Response,
  secure: boolean,
): void {
  const flags = sessionFlags(secure);
  response.setHeader('Set-Cookie', [
    `freebay_access=; Path=/; Max-Age=0; ${flags}`,
    `freebay_refresh=; Path=/auth/web/session; Max-Age=0; ${flags}`,
  ]);
}
