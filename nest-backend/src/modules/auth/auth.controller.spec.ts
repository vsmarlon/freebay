import { Test, TestingModule } from '@nestjs/testing';
import { AuthUser, JwtPayload, JwtTokenType } from '@/shared/core/types';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthController } from './auth.controller';
import { AuthWebSessionController } from './auth-web-session.controller';
import { right } from '@/shared/core/either';
import { RegisterUseCase } from './usecases/register.usecase';
import { LoginUseCase } from './usecases/login.usecase';
import { GoogleAuthUseCase } from './usecases/google-auth.usecase';
import { AppleAuthUseCase } from './usecases/apple-auth.usecase';
import { CompleteProfileUseCase } from './usecases/complete-profile.usecase';
import { RefreshMobileSessionUseCase } from './usecases/refresh-mobile-session.usecase';
import { LogoutSessionUseCase } from './usecases/logout-session.usecase';
import { CheckUsernameAvailabilityUseCase } from './usecases/check-username-availability.usecase';
import { RequestPasswordRecoveryUseCase } from './usecases/request-password-recovery.usecase';
import { VerifyPasswordRecoveryCodeUseCase } from './usecases/verify-password-recovery-code.usecase';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';
import { BiometricLoginUseCase } from './usecases/biometric-login.usecase';
import { EnrollBiometricUseCase } from './usecases/enroll-biometric.usecase';
import { RevokeBiometricUseCase } from './usecases/revoke-biometric.usecase';
import { RequestMagicLinkUseCase } from './usecases/request-magic-link.usecase';
import { ConsumeMagicLinkUseCase } from './usecases/consume-magic-link.usecase';
import { RefreshWebSessionUseCase } from './usecases/refresh-web-session.usecase';
import { LogoutWebSessionUseCase } from './usecases/logout-web-session.usecase';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { OriginGuard } from '@/shared/guards/origin.guard';
import { APP_GUARD } from '@nestjs/core';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { request as httpRequest, IncomingMessage } from 'http';
import { UserRole } from '@prisma/client';

type JsonRequest = {
  method: 'POST';
  path: string;
  body?: object;
  cookie?: string;
  origin?: string;
  authorization?: string;
};

type JsonResponse = {
  statusCode: number;
  headers: IncomingMessage['headers'];
  body: string;
};

const readResponse = (response: IncomingMessage): Promise<JsonResponse> =>
  new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    response.on('data', (chunk: Buffer) => chunks.push(chunk));
    response.on('end', () => resolve({
      statusCode: response.statusCode ?? 0,
      headers: response.headers,
      body: Buffer.concat(chunks).toString('utf8'),
    }));
    response.on('error', reject);
  });

describe('AuthController web session endpoints', () => {
  let module: TestingModule;
  let app: ReturnType<TestingModule['createNestApplication']>;
  let authService: {
    requestMagicLink: jest.Mock;
    consumeMagicLink: jest.Mock;
    refreshWebSession: jest.Mock;
    logoutWebSession: jest.Mock;
    enrollBiometricToken: jest.Mock;
  };
  let jwtService: { verify: jest.Mock };
  let tokenValidator: { verifyAndValidate: jest.Mock };

  const post = async ({ method, path, body, cookie, origin, authorization }: JsonRequest): Promise<JsonResponse> => {
    const address = app.getHttpServer().address();
    if (address === null || typeof address === 'string') throw new Error('Test server did not bind to a port');
    const result = new Promise<JsonResponse>((resolve, reject) => {
      const request = httpRequest({ hostname: '127.0.0.1', port: address.port, path, method, headers: {
         'Content-Type': 'application/json',
          ...(origin ? { Origin: origin } : {}),
          ...(authorization ? { Authorization: authorization } : {}),
        ...(cookie ? { Cookie: cookie } : {}),
      } }, (response) => {
        void readResponse(response).then(resolve, reject);
      });
      if (body) request.write(JSON.stringify(body));
      request.end();
    });
    return result;
  };

  beforeAll(async () => {
    authService = {
      requestMagicLink: jest.fn().mockResolvedValue(right(undefined)),
      consumeMagicLink: jest.fn().mockResolvedValue(right({
        user: { id: 'user-1', email: 'user@example.com' },
        tokens: { token: 'access/token', refreshToken: 'refresh/token' },
      })),
      refreshWebSession: jest.fn().mockResolvedValue(right({ token: 'rotated/access', refreshToken: 'rotated/refresh' })),
      logoutWebSession: jest.fn().mockResolvedValue(right({ message: 'Logout realizado' })),
      enrollBiometricToken: jest.fn().mockResolvedValue(right({ biometricToken: 'enrolled-token' })),
    };
    jwtService = { verify: jest.fn().mockReturnValue({
      userId: 'user-1', role: UserRole.USER, type: JwtTokenType.REFRESH, jti: 'refresh-jti', exp: 500,
    } satisfies JwtPayload) };
    tokenValidator = { verifyAndValidate: jest.fn().mockResolvedValue({
      userId: 'user-1', role: UserRole.USER, type: JwtTokenType.ACCESS, jti: 'access-jti', exp: 500,
    } satisfies AuthUser) };
    module = await Test.createTestingModule({
      controllers: [AuthController, AuthWebSessionController],
      providers: [
        { provide: RegisterUseCase, useValue: { execute: jest.fn() } },
        { provide: LoginUseCase, useValue: { execute: jest.fn() } },
        { provide: GoogleAuthUseCase, useValue: { execute: jest.fn() } },
        { provide: AppleAuthUseCase, useValue: { execute: jest.fn() } },
        { provide: CompleteProfileUseCase, useValue: { execute: jest.fn() } },
        { provide: RefreshMobileSessionUseCase, useValue: { execute: jest.fn() } },
        { provide: LogoutSessionUseCase, useValue: { execute: jest.fn() } },
        { provide: CheckUsernameAvailabilityUseCase, useValue: { execute: jest.fn() } },
        { provide: RequestPasswordRecoveryUseCase, useValue: { execute: jest.fn() } },
        { provide: VerifyPasswordRecoveryCodeUseCase, useValue: { execute: jest.fn() } },
        { provide: ResetPasswordUseCase, useValue: { execute: jest.fn() } },
        { provide: BiometricLoginUseCase, useValue: { execute: jest.fn() } },
        { provide: EnrollBiometricUseCase, useValue: { execute: authService.enrollBiometricToken } },
        { provide: RevokeBiometricUseCase, useValue: { execute: jest.fn() } },
        { provide: RequestMagicLinkUseCase, useValue: { execute: authService.requestMagicLink } },
        { provide: ConsumeMagicLinkUseCase, useValue: { execute: authService.consumeMagicLink } },
        { provide: RefreshWebSessionUseCase, useValue: { execute: authService.refreshWebSession } },
        { provide: LogoutWebSessionUseCase, useValue: { execute: authService.logoutWebSession } },
        { provide: JwtService, useValue: jwtService },
        { provide: ConfigService, useValue: { get: jest.fn((key: string) => key === 'NODE_ENV' ? 'production' : undefined) } },
        JwtAuthGuard,
        OriginGuard,
        { provide: APP_GUARD, useClass: JwtAuthGuard },
        { provide: APP_GUARD, useClass: OriginGuard },
        { provide: JwtTokenValidatorService, useValue: tokenValidator },
      ],
    }).overrideProvider(ConfigService).useValue({ get: jest.fn((key: string) => key === 'NODE_ENV' ? 'production' : key === 'WEB_APP_URL' ? 'https://app.example.com' : undefined) }).compile();
    app = module.createNestApplication();
    await app.init();
    await app.listen(0);
  });

  afterAll(async () => app.close());

  it('returns a generic magic-link request response without account enumeration', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/magic-link/request', origin: 'https://app.example.com', body: { email: 'unknown@example.com', consent: true, locale: 'en' } });

    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toEqual({ sent: true });
    expect(JSON.parse(response.body)).not.toHaveProperty('user');
    expect(JSON.parse(response.body)).not.toHaveProperty('account');
  });

  it('forwards the trusted origin and deletion purpose for the public web deletion flow', async () => {
    authService.requestMagicLink.mockClear();

    const response = await post({
      method: 'POST', path: '/auth/web/magic-link/request', origin: 'https://app.example.com',
      body: { email: 'user@example.com', consent: true, locale: 'en', purpose: 'account-deletion' },
    });

    expect(response.statusCode).toBe(200);
    expect(authService.requestMagicLink).toHaveBeenCalledWith(expect.objectContaining({
      purpose: 'account-deletion', returnOrigin: 'https://app.example.com',
    }));
  });

  it('enrolls a biometric token from the authenticated access-token user', async () => {
    const response = await post({
      method: 'POST',
      path: '/auth/biometric-token/enroll',
      authorization: 'Bearer access-token',
      body: { userId: 'attacker-controlled' },
    });

    expect(response.statusCode).toBe(201);
    expect(JSON.parse(response.body)).toEqual({ biometricToken: 'enrolled-token' });
    expect(authService.enrollBiometricToken).toHaveBeenCalledWith(expect.objectContaining({ userId: 'user-1' }));
  });

  it.each([undefined, 'https://evil.example.com'])('rejects magic-link requests without a trusted Origin (%s)', async (origin) => {
    authService.requestMagicLink.mockClear();
    const response = await post({ method: 'POST', path: '/auth/web/magic-link/request', origin, body: { email: 'unknown@example.com', consent: true, locale: 'en' } });
    expect(response.statusCode).toBe(401);
    expect(authService.requestMagicLink).not.toHaveBeenCalled();
  });

  it('sets HttpOnly, SameSite, Secure production cookies when consuming a magic link', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/magic-link/consume', origin: 'https://app.example.com', body: { token: 'a'.repeat(43) } });

    expect(response.headers['set-cookie']).toEqual([
      'freebay_access=access%2Ftoken; Path=/; Max-Age=900; HttpOnly; Secure; SameSite=Lax',
      'freebay_refresh=refresh%2Ftoken; Path=/auth/web/session; Max-Age=604800; HttpOnly; Secure; SameSite=Lax',
    ]);
  });

  it('rotates the web session and writes the rotated cookie pair', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/session/refresh', origin: 'https://app.example.com', cookie: 'freebay_refresh=refresh-cookie' });

    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toEqual({ refreshed: true });
    expect(authService.refreshWebSession).toHaveBeenCalledWith(expect.objectContaining({ userId: 'user-1' }));
    expect(tokenValidator.verifyAndValidate).toHaveBeenCalledWith('refresh-cookie', [JwtTokenType.REFRESH]);
    expect(response.headers['set-cookie']).toEqual([
      'freebay_access=rotated%2Faccess; Path=/; Max-Age=900; HttpOnly; Secure; SameSite=Lax',
      'freebay_refresh=rotated%2Frefresh; Path=/auth/web/session; Max-Age=604800; HttpOnly; Secure; SameSite=Lax',
    ]);
  });

  it('clears both cookies using the same paths and security options on logout', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/session/logout', origin: 'https://app.example.com', cookie: 'freebay_access=access-cookie; freebay_refresh=refresh-cookie' });

    expect(response.statusCode).toBe(201);
    expect(jwtService.verify).toHaveBeenCalledWith('refresh-cookie');
    expect(tokenValidator.verifyAndValidate).toHaveBeenCalledWith('access-cookie', [JwtTokenType.ACCESS]);
    expect(response.headers['set-cookie']).toEqual([
      'freebay_access=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax',
      'freebay_refresh=; Path=/auth/web/session; Max-Age=0; HttpOnly; Secure; SameSite=Lax',
    ]);
  });

  it.each([undefined, 'https://evil.example.com'])('rejects web cookie endpoints without a trusted Origin (%s)', async (origin) => {
    authService.consumeMagicLink.mockClear();
    const response = await post({ method: 'POST', path: '/auth/web/magic-link/consume', origin, body: { token: 'a'.repeat(43) } });
    expect(response.statusCode).toBe(401);
    expect(authService.consumeMagicLink).not.toHaveBeenCalled();
  });

  it.each([
    ['/auth/web/session/refresh', 'freebay_refresh=refresh-cookie'],
    ['/auth/web/session/logout', 'freebay_access=access-cookie'],
  ])('rejects opted-in mutation %s without Origin', async (path, cookie) => {
    authService.refreshWebSession.mockClear();
    authService.logoutWebSession.mockClear();
    const response = await post({ method: 'POST', path, cookie });

    expect(response.statusCode).toBe(401);
    expect(authService.refreshWebSession).not.toHaveBeenCalled();
    expect(authService.logoutWebSession).not.toHaveBeenCalled();
  });

  it('rejects duplicate session cookies instead of selecting one', async () => {
    authService.refreshWebSession.mockClear();
    const response = await post({ method: 'POST', path: '/auth/web/session/refresh', origin: 'https://app.example.com', cookie: 'freebay_refresh=one; freebay_refresh=two' });
    expect(response.statusCode).toBe(401);
    expect(authService.refreshWebSession).not.toHaveBeenCalled();
  });

  it('rejects malformed session cookie encoding without a server error', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/session/refresh', origin: 'https://app.example.com', cookie: 'freebay_refresh=%' });
    expect(response.statusCode).toBe(401);
  });
});
