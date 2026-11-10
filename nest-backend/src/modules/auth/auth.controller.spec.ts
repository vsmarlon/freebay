import { StepUpPurpose } from '@/shared/auth/biometric-credential.service';
import { Test, TestingModule } from '@nestjs/testing';
import { AuthUser, JwtPayload, JwtTokenType } from '@/shared/core/types';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthController } from './auth.controller';
import { AuthWebSessionController } from './auth-web-session.controller';
import { left, right } from '@/shared/core/either';
import { InvalidGoogleTokenError } from '@/shared/core/errors';
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
import { CreateBiometricChallengeUseCase } from './usecases/create-biometric-challenge.usecase';
import { CreateBiometricEnrollmentChallengeUseCase } from './usecases/create-biometric-enrollment-challenge.usecase';
import { CreateStepUpUseCase } from './usecases/create-step-up.usecase';
import { RequestWebStepUpMagicLinkUseCase } from './usecases/request-web-step-up-magic-link.usecase';
import { RequestMagicLinkUseCase } from './usecases/request-magic-link.usecase';
import { ConsumeMagicLinkUseCase } from './usecases/consume-magic-link.usecase';
import { RefreshWebSessionUseCase } from './usecases/refresh-web-session.usecase';
import { LogoutWebSessionUseCase } from './usecases/logout-web-session.usecase';
import { RequestWebPasswordResetUseCase } from './usecases/request-web-password-reset.usecase';
import { ResetWebPasswordUseCase } from './usecases/reset-web-password.usecase';
import { RequestEmailVerificationUseCase } from './usecases/request-email-verification.usecase';
import { ConfirmEmailVerificationUseCase } from './usecases/confirm-email-verification.usecase';
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
    login: jest.Mock;
    google: jest.Mock;
    apple: jest.Mock;
    requestMagicLink: jest.Mock;
    consumeMagicLink: jest.Mock;
    refreshWebSession: jest.Mock;
    logoutWebSession: jest.Mock;
    enrollBiometricToken: jest.Mock;
  };
  let jwtService: { verify: jest.Mock };
  let tokenValidator: { verifyAndValidate: jest.Mock };
  let createStepUp: { execute: jest.Mock };
  let requestStepUpMagicLink: { execute: jest.Mock };
  let requestWebPasswordReset: { execute: jest.Mock };
  let resetWebPassword: { execute: jest.Mock };
  let registerUseCase: { execute: jest.Mock };

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
      login: jest.fn().mockResolvedValue(right({ user: { id: 'user-1', email: 'user@example.com' }, token: 'access-token', refreshToken: 'refresh-token' })),
      google: jest.fn().mockResolvedValue(right({ user: { id: 'user-1', email: 'user@example.com' }, token: 'access-token', refreshToken: 'refresh-token' })),
      apple: jest.fn().mockResolvedValue(right({ user: { id: 'user-1', email: 'user@example.com' }, token: 'access-token', refreshToken: 'refresh-token' })),
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
    createStepUp = { execute: jest.fn().mockResolvedValue(right({ stepUpToken: 'step-up', expiresAt: new Date(Date.now() + 300_000).toISOString() })) };
    requestStepUpMagicLink = { execute: jest.fn().mockResolvedValue(right({ sent: true })) };
    requestWebPasswordReset = { execute: jest.fn().mockResolvedValue(right(undefined)) };
    resetWebPassword = { execute: jest.fn().mockResolvedValue(right(undefined)) };
    registerUseCase = { execute: jest.fn().mockResolvedValue(right({ user: { id: 'new-user', email: 'new@example.com' }, token: 'new-access', refreshToken: 'new-refresh' })) };
    module = await Test.createTestingModule({
      controllers: [AuthController, AuthWebSessionController],
      providers: [
        { provide: RegisterUseCase, useValue: registerUseCase },
        { provide: LoginUseCase, useValue: { execute: authService.login } },
        { provide: GoogleAuthUseCase, useValue: { execute: authService.google } },
        { provide: AppleAuthUseCase, useValue: { execute: authService.apple } },
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
        { provide: CreateBiometricChallengeUseCase, useValue: { execute: jest.fn().mockResolvedValue(right({ challengeId: 'challenge-1', challenge: 'freebay:v1:login:login:-:nonce' })) } },
        { provide: CreateBiometricEnrollmentChallengeUseCase, useValue: { execute: jest.fn().mockResolvedValue(right({ challengeId: 'enrollment-1', challenge: 'freebay:v1:biometric_enroll:nonce' })) } },
        { provide: CreateStepUpUseCase, useValue: createStepUp },
        { provide: RequestWebStepUpMagicLinkUseCase, useValue: requestStepUpMagicLink },
        { provide: RequestWebPasswordResetUseCase, useValue: requestWebPasswordReset },
        { provide: ResetWebPasswordUseCase, useValue: resetWebPassword },
        { provide: RequestEmailVerificationUseCase, useValue: { execute: jest.fn().mockResolvedValue(right({ sent: true })) } },
        { provide: ConfirmEmailVerificationUseCase, useValue: { execute: jest.fn().mockResolvedValue(right({ user: { id: 'user-1', email: 'user@example.com' }, emailVerified: true })) } },
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

  it('exposes purpose-specific web recovery without authenticating or revealing account status', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/password-reset/request', origin: 'https://app.example.com', body: { email: 'unknown@example.com', locale: 'en' } });
    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toEqual({ sent: true });
    expect(requestWebPasswordReset.execute).toHaveBeenCalledWith({ email: 'unknown@example.com', locale: 'en' });
    expect(response.headers['set-cookie']).toBeUndefined();
  });

  it('rejects web password recovery from an untrusted origin', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/password-reset/consume', origin: 'https://evil.example.com', body: { token: 'A'.repeat(43), newPassword: 'new-password-123' } });
    expect(response.statusCode).toBe(401);
    expect(resetWebPassword.execute).not.toHaveBeenCalled();
  });

  it('resets browser credentials without creating an authenticated session', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/password-reset/consume', origin: 'https://app.example.com', body: { token: 'A'.repeat(43), newPassword: 'new-password-123' } });
    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toEqual({ reset: true });
    expect(response.headers['set-cookie']).toBeUndefined();
  });

  it('issues browser login only through HttpOnly cookies and never returns JWTs', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/login', origin: 'https://app.example.com', body: { email: 'user@example.com', password: 'password123' } });

    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toEqual({ user: { id: 'user-1', email: 'user@example.com' } });
    expect(JSON.parse(response.body)).not.toHaveProperty('token');
    expect(JSON.parse(response.body)).not.toHaveProperty('refreshToken');
    expect(response.headers['set-cookie']).toEqual([
      'freebay_access=access-token; Path=/; Max-Age=900; HttpOnly; Secure; SameSite=Lax',
      'freebay_refresh=refresh-token; Path=/auth/web/session; Max-Age=604800; HttpOnly; Secure; SameSite=Lax',
    ]);
  });

  it('registers a browser user using HttpOnly cookies rather than returning session tokens', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/register', origin: 'https://app.example.com', body: { displayName: 'New User', username: 'new_user', email: 'new@example.com', password: 'strong-password-123' } });
    expect(response.statusCode).toBe(201);
    expect(JSON.parse(response.body)).toEqual({ user: { id: 'new-user', email: 'new@example.com' } });
    expect(JSON.parse(response.body)).not.toHaveProperty('token');
    expect(response.headers['set-cookie']).toEqual([
      'freebay_access=new-access; Path=/; Max-Age=900; HttpOnly; Secure; SameSite=Lax',
      'freebay_refresh=new-refresh; Path=/auth/web/session; Max-Age=604800; HttpOnly; Secure; SameSite=Lax',
    ]);
  });

  it('rejects browser registration from an untrusted origin before account creation', async () => {
    registerUseCase.execute.mockClear();
    const response = await post({ method: 'POST', path: '/auth/web/register', origin: 'https://evil.example.com', body: { displayName: 'New User', username: 'new_user', email: 'new@example.com', password: 'strong-password-123' } });
    expect(response.statusCode).toBe(401);
    expect(registerUseCase.execute).not.toHaveBeenCalled();
  });

  it('rejects browser provider issuance from an untrusted origin before authenticating', async () => {
    const response = await post({ method: 'POST', path: '/auth/web/google', origin: 'https://evil.example.com', body: { idToken: 'provider-id-token' } });

    expect(response.statusCode).toBe(401);
    expect(authService.google).not.toHaveBeenCalled();
    expect(response.headers['set-cookie']).toBeUndefined();
  });

  it('does not set session cookies when the browser provider credential is rejected', async () => {
    authService.google.mockResolvedValueOnce(left(new InvalidGoogleTokenError()));
    const response = await post({ method: 'POST', path: '/auth/web/google', origin: 'https://app.example.com', body: { idToken: 'invalid-id-token' } });

    expect(response.statusCode).toBe(401);
    expect(response.headers['set-cookie']).toBeUndefined();
    expect(JSON.parse(response.body)).not.toHaveProperty('token');
  });

  it.each([
    ['/auth/web/google', { idToken: 'google-id-token' }, 'google'],
    ['/auth/web/apple', { identityToken: 'apple-id-token', authorizationCode: 'single-use-code', rawNonce: 'n'.repeat(32) }, 'apple'],
  ] as const)('keeps provider session credentials in cookies for %s', async (path, body, provider) => {
    const response = await post({ method: 'POST', path, origin: 'https://app.example.com', body });

    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toEqual({ user: { id: 'user-1', email: 'user@example.com' } });
    expect(JSON.parse(response.body)).not.toHaveProperty('token');
    expect(JSON.parse(response.body)).not.toHaveProperty('refreshToken');
    expect(response.headers['set-cookie']).toHaveLength(2);
    expect(authService[provider]).toHaveBeenCalled();
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
      body: { userId: 'attacker-controlled', stepUpToken: 'step-up-proof', publicKey: Buffer.from('public-key').toString('base64') },
    });

    expect(response.statusCode).toBe(201);
    expect(JSON.parse(response.body)).toEqual({ biometricToken: 'enrolled-token' });
    expect(authService.enrollBiometricToken).toHaveBeenCalledWith(expect.objectContaining({ userId: 'user-1' }), 'step-up-proof', Buffer.from('public-key').toString('base64'), undefined, undefined);
  });

  it('offers the native enrollment challenge only to access tokens', async () => {
    const response = await post({ method: 'POST', path: '/auth/biometric-token/enroll/challenge', authorization: 'Bearer access-token', body: { publicKey: 'public-key' } });
    expect(response.statusCode).toBe(200);
    expect(tokenValidator.verifyAndValidate).toHaveBeenLastCalledWith('access-token', [JwtTokenType.ACCESS]);
    const rejected = await post({ method: 'POST', path: '/auth/biometric-token/enroll/challenge', body: { publicKey: 'public-key' } });
    expect(rejected.statusCode).toBe(401);
  });

  it('offers fresh proof through the same-origin web session cookie route', async () => {
    const response = await post({
      method: 'POST', path: '/auth/web/step-up', origin: 'https://app.example.com', cookie: 'freebay_access=access-cookie',
      body: { purpose: StepUpPurpose.EXPORT_DATA, proof: { kind: 'password', password: 'secret' } },
    });

    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toEqual(expect.objectContaining({ stepUpToken: 'step-up' }));
    expect(createStepUp.execute).toHaveBeenCalledWith(expect.objectContaining({ userId: 'user-1' }), expect.objectContaining({ purpose: StepUpPurpose.EXPORT_DATA }), { web: true });
  });

  it('requests action-bound email proof only with a trusted origin and the current cookie identity', async () => {
    const response = await post({
      method: 'POST', path: '/auth/web/step-up/magic-link/request', origin: 'https://app.example.com', cookie: 'freebay_access=access-cookie',
      body: { purpose: StepUpPurpose.CANCEL_ORDER, resourceId: '550e8400-e29b-41d4-a716-446655440000', locale: 'en', consent: true },
    });

    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toEqual({ sent: true });
    expect(JSON.parse(response.body)).not.toHaveProperty('token');
    expect(JSON.parse(response.body)).not.toHaveProperty('stepUpToken');
    expect(requestStepUpMagicLink.execute).toHaveBeenCalledWith(expect.objectContaining({
      user: expect.objectContaining({ userId: 'user-1' }),
      body: expect.objectContaining({ purpose: StepUpPurpose.CANCEL_ORDER, resourceId: '550e8400-e29b-41d4-a716-446655440000' }),
      ip: expect.any(String),
    }));
  });

  it.each([undefined, 'https://evil.example.com'])('rejects sensitive-action email requests without trusted Origin (%s)', async (origin) => {
    requestStepUpMagicLink.execute.mockClear();
    const response = await post({
      method: 'POST', path: '/auth/web/step-up/magic-link/request', origin, cookie: 'freebay_access=access-cookie',
      body: { purpose: StepUpPurpose.EXPORT_DATA, locale: 'en', consent: true },
    });

    expect(response.statusCode).toBe(401);
    expect(requestStepUpMagicLink.execute).not.toHaveBeenCalled();
  });

  it('returns only the validated access cookie for browser memory and disables caching', async () => {
    const response = await post({
      method: 'POST', path: '/auth/web/session/access-token',
      origin: 'https://app.example.com', cookie: 'freebay_access=access-cookie',
    });

    expect(response.statusCode).toBe(200);
    expect(response.headers['cache-control']).toBe('no-store');
    expect(JSON.parse(response.body)).toEqual({ token: 'access-cookie' });
    expect(response.headers['set-cookie']).toBeUndefined();
  });

  it('does not accept a bearer token for the cookie-only browser access-token exchange', async () => {
    const response = await post({
      method: 'POST', path: '/auth/web/session/access-token',
      origin: 'https://app.example.com', authorization: 'Bearer access-token',
    });

    expect(response.statusCode).toBe(401);
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

  it('serves the email-verification request only to an authenticated access-token user', async () => {
    const accepted = await post({
      method: 'POST', path: '/auth/verify-email/request', authorization: 'Bearer access-token', body: { locale: 'en' },
    });
    expect(accepted.statusCode).toBe(200);
    expect(JSON.parse(accepted.body)).toEqual({ sent: true });

    const rejected = await post({ method: 'POST', path: '/auth/verify-email/request', body: { locale: 'en' } });
    expect(rejected.statusCode).toBe(401);
  });

  it('consumes the emailed token with the authenticated identity and returns the verified projection', async () => {
    const response = await post({
      method: 'POST', path: '/auth/verify-email/confirm', authorization: 'Bearer access-token', body: { token: 'token-from-email' },
    });
    expect(response.statusCode).toBe(200);
    expect(JSON.parse(response.body)).toEqual({ user: { id: 'user-1', email: 'user@example.com' }, emailVerified: true });
  });
});
