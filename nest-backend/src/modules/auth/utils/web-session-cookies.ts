import { UnauthorizedException } from '@nestjs/common';
import { JwtTokenType } from '@/shared/core/types';

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
