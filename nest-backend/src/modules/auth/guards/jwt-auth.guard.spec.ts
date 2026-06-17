import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtAuthGuard } from './jwt-auth.guard';
import { ALLOWED_TOKEN_TYPES_KEY } from './token-types.decorator';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';

describe('JwtAuthGuard', () => {
  let guard: JwtAuthGuard;
  let reflector: { getAllAndOverride: jest.Mock };
  let tokenValidator: { verifyAndValidate: jest.Mock };

  const createContext = (authorization?: string) => {
    const request: { headers: Record<string, string | undefined>; user?: unknown } = {
      headers: { authorization },
    };

    const context = {
      switchToHttp: () => ({ getRequest: () => request }),
      getHandler: () => 'handler',
      getClass: () => 'class',
    } as unknown as ExecutionContext;

    return { context, request };
  };

  beforeEach(() => {
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

    guard = new JwtAuthGuard(
      reflector as unknown as Reflector,
      tokenValidator as unknown as JwtTokenValidatorService,
    );
  });

  it('rejects requests without token', async () => {
    const { context } = createContext();

    await expect(guard.canActivate(context)).rejects.toThrow(UnauthorizedException);
  });

  it('allows valid access token by default', async () => {
    const { context, request } = createContext('Bearer token');
    tokenValidator.verifyAndValidate.mockResolvedValue({
      userId: 'user-1',
      role: 'USER',
      type: 'access',
      jti: 'jti-1',
      iat: 200,
      exp: 500,
    });

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.user).toEqual(expect.objectContaining({ userId: 'user-1', type: 'access' }));
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
        return ['refresh'];
      }
      return false;
    });
    tokenValidator.verifyAndValidate.mockResolvedValue({
      userId: 'user-1',
      role: 'USER',
      type: 'refresh',
      jti: 'jti-1',
      iat: 200,
      exp: 500,
    });

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(request.user).toEqual(expect.objectContaining({ type: 'refresh' }));
  });

  it('rejects tokens issued before user invalidation cutoff', async () => {
    const { context } = createContext('Bearer token');
    tokenValidator.verifyAndValidate.mockRejectedValue(new UnauthorizedException('Sessão expirada'));

    await expect(guard.canActivate(context)).rejects.toThrow('Sessão expirada');
  });
});
