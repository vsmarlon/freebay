import { Test, TestingModule } from '@nestjs/testing';
import { UnauthorizedException } from '@nestjs/common';
import { createExecutionContext } from '@/shared/testing/test-doubles';
import { Reflector } from '@nestjs/core';
import { JwtAuthGuard } from './jwt-auth.guard';
import { ALLOWED_TOKEN_TYPES_KEY } from './token-types.decorator';
import { WEB_COOKIE_AUTH_KEY } from './web-cookie-auth.decorator';
import { JwtTokenType } from '@/shared/core/types';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';

describe('JwtAuthGuard', () => {
  let guard: JwtAuthGuard;
  let reflector: { getAllAndOverride: jest.Mock };
  let tokenValidator: { verifyAndValidate: jest.Mock };

  const createContext = (authorization?: string, cookie?: string) => {
    const request: { headers: Record<string, string | undefined>; user?: unknown } = {
      headers: { authorization, cookie },
    };

    const context = createExecutionContext({ request });

    return { context, request };
  };

  beforeEach(async () => {
    reflector = {
      getAllAndOverride: jest.fn((key: string) => {
        if (key === ALLOWED_TOKEN_TYPES_KEY) {
          return undefined;
        }
        return false;
      }),
    };
    tokenValidator = {
      verifyAndValidate: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        JwtAuthGuard,
        { provide: Reflector, useValue: reflector },
        { provide: JwtTokenValidatorService, useValue: tokenValidator },
      ],
    }).compile();

    guard = module.get(JwtAuthGuard);
  });

  it('rejects requests without token', async () => {
    const { context } = createContext();

    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('treats malformed percent-encoded cookies as absent', async () => {
    const { context } = createContext(undefined, 'freebay_access=%');
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
    expect(tokenValidator.verifyAndValidate).not.toHaveBeenCalled();
  });

  it('ignores access cookies on ordinary protected routes', async () => {
    const { context } = createContext(undefined, 'freebay_access=encoded%2Ftoken');
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
    expect(tokenValidator.verifyAndValidate).not.toHaveBeenCalled();
  });

  it('rejects duplicate access cookies instead of selecting one', async () => {
    const { context } = createContext(undefined, 'freebay_access=one; freebay_access=two');
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
    expect(tokenValidator.verifyAndValidate).not.toHaveBeenCalled();
  });

  it('keeps Bearer priority without parsing an ambiguous cookie', async () => {
    const { context } = createContext('Bearer header-token', 'freebay_access=one; freebay_access=two');
    tokenValidator.verifyAndValidate.mockResolvedValue({ userId: 'u1', type: JwtTokenType.ACCESS });
    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(tokenValidator.verifyAndValidate).toHaveBeenCalledWith('header-token', [JwtTokenType.ACCESS]);
  });

  it('allows valid access token by default', async () => {
    const { context, request } = createContext('Bearer token');
    tokenValidator.verifyAndValidate.mockResolvedValue({
      userId: 'user-1',
      role: 'USER',
      type: JwtTokenType.ACCESS,
      jti: 'jti-1',
      iat: 200,
      exp: 500,
    });

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.user).toEqual(expect.objectContaining({ userId: 'user-1', type: JwtTokenType.ACCESS }));
  });

  it('keeps preferring a valid Authorization header when an access cookie is also present', async () => {
    const { context } = createContext('Bearer header-token', 'freebay_access=cookie-token');
    tokenValidator.verifyAndValidate.mockResolvedValue({
      userId: 'user-1',
      role: 'USER',
      type: JwtTokenType.ACCESS,
      jti: 'jti-1',
      iat: 200,
      exp: 500,
    });

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(tokenValidator.verifyAndValidate).toHaveBeenCalledWith('header-token', [JwtTokenType.ACCESS]);
  });

  it('accepts a valid access cookie only on an opted-in route', async () => {
    const { context } = createContext(undefined, 'freebay_access=cookie-token');
    reflector.getAllAndOverride.mockImplementation((key: string) => key === WEB_COOKIE_AUTH_KEY ? true : undefined);
    tokenValidator.verifyAndValidate.mockResolvedValue({
      userId: 'user-1',
      role: 'USER',
      type: JwtTokenType.ACCESS,
      jti: 'jti-1',
      iat: 200,
      exp: 500,
    });

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(tokenValidator.verifyAndValidate).toHaveBeenCalledWith('cookie-token', [JwtTokenType.ACCESS]);
  });

  it('selects only the refresh cookie for a cookie-authenticated refresh route', async () => {
    const { context } = createContext('Bearer header-token', 'freebay_access=access-token; freebay_refresh=refresh-token');
    reflector.getAllAndOverride.mockImplementation((key: string) => {
      if (key === ALLOWED_TOKEN_TYPES_KEY) return [JwtTokenType.REFRESH];
      if (key === WEB_COOKIE_AUTH_KEY) return true;
      return undefined;
    });
    tokenValidator.verifyAndValidate.mockResolvedValue({
      userId: 'user-1',
      role: 'USER',
      type: JwtTokenType.REFRESH,
      jti: 'jti-1',
      iat: 200,
      exp: 500,
    });

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(tokenValidator.verifyAndValidate).toHaveBeenCalledWith('refresh-token', [JwtTokenType.REFRESH]);
  });

  it('rejects duplicate refresh cookies for a cookie-authenticated refresh route', async () => {
    const { context } = createContext(undefined, 'freebay_refresh=one; freebay_refresh=two');
    reflector.getAllAndOverride.mockImplementation((key: string) => {
      if (key === ALLOWED_TOKEN_TYPES_KEY) return [JwtTokenType.REFRESH];
      if (key === WEB_COOKIE_AUTH_KEY) return true;
      return undefined;
    });
    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
    expect(tokenValidator.verifyAndValidate).not.toHaveBeenCalled();
  });

  it('rejects blacklisted tokens', async () => {
    const { context } = createContext('Bearer token');
    tokenValidator.verifyAndValidate.mockRejectedValue(new UnauthorizedException('Token revogado'));

    await expect(guard.canActivate(context)).rejects.toThrow('Token revogado');
  });

  it('rejects refresh token on normal protected routes', async () => {
    const { context } = createContext('Bearer token');
    tokenValidator.verifyAndValidate.mockRejectedValue(new UnauthorizedException('Tipo de token inválido'));

    await expect(guard.canActivate(context)).rejects.toThrow('Tipo de token inválido');
  });

  it('allows refresh token when route explicitly requests it', async () => {
    const { context, request } = createContext('Bearer token');
    reflector.getAllAndOverride.mockImplementation((key: string) => {
      if (key === ALLOWED_TOKEN_TYPES_KEY) {
        return [JwtTokenType.REFRESH];
      }
      return false;
    });
    tokenValidator.verifyAndValidate.mockResolvedValue({
      userId: 'user-1',
      role: 'USER',
      type: JwtTokenType.REFRESH,
      jti: 'jti-1',
      iat: 200,
      exp: 500,
    });

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.user).toEqual(expect.objectContaining({ type: JwtTokenType.REFRESH }));
  });

  it('rejects tokens issued before user invalidation cutoff', async () => {
    const { context } = createContext('Bearer token');
    tokenValidator.verifyAndValidate.mockRejectedValue(new UnauthorizedException('Sessão expirada'));

    await expect(guard.canActivate(context)).rejects.toThrow('Sessão expirada');
  });
});
