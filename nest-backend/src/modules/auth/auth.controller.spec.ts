import { Test, TestingModule } from '@nestjs/testing';
import { AuthUser, JwtPayload, JwtTokenType } from '@/shared/core/types';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { WebOriginGuard } from './guards/web-origin.guard';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { request as httpRequest, IncomingMessage } from 'http';

type JsonRequest = {
  method: 'POST';
  path: string;
  body?: object;
  cookie?: string;
  origin?: string;
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
  };
  let jwtService: { verify: jest.Mock };
  let tokenValidator: { verifyAndValidate: jest.Mock };

  const post = async ({ method, path, body, cookie, origin }: JsonRequest): Promise<JsonResponse> => {
    const address = app.getHttpServer().address();
    if (address === null || typeof address === 'string') throw new Error('Test server did not bind to a port');
    const result = new Promise<JsonResponse>((resolve, reject) => {
      const request = httpRequest({ hostname: '127.0.0.1', port: address.port, path, method, headers: {
         'Content-Type': 'application/json',
         ...(origin ? { Origin: origin } : {}),
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
      requestMagicLink: jest.fn().mockResolvedValue({ sent: true }),
      consumeMagicLink: jest.fn().mockResolvedValue({
        user: { id: 'user-1', email: 'user@example.com' },
        tokens: { token: 'access/token', refreshToken: 'refresh/token' },
      }),
      refreshWebSession: jest.fn().mockResolvedValue({ token: 'rotated/access', refreshToken: 'rotated/refresh' }),
      logoutWebSession: jest.fn().mockResolvedValue({ message: 'Logout realizado' }),
    };
    jwtService = { verify: jest.fn().mockReturnValue({
      userId: 'user-1', role: 'USER', type: JwtTokenType.REFRESH, jti: 'refresh-jti', exp: 500,
    } satisfies JwtPayload) };
    tokenValidator = { verifyAndValidate: jest.fn().mockResolvedValue({
      userId: 'user-1', role: 'USER', type: JwtTokenType.ACCESS, jti: 'access-jti', exp: 500,
    } satisfies AuthUser) };
    module = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        { provide: AuthService, useValue: authService },
        { provide: JwtService, useValue: jwtService },
        { provide: ConfigService, useValue: { get: jest.fn((key: string) => key === 'NODE_ENV' ? 'production' : undefined) } },
        WebOriginGuard,
        { provide: JwtAuthGuard, useClass: JwtAuthGuard },
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
