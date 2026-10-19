import { Controller } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UserRole } from '@prisma/client';
import { CurrentUser, PostAuth } from '@/shared/decorators';
import { AuthUser, JwtPayload, JwtTokenType } from '@/shared/core/types';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { AllowTokenTypes } from './guards/token-types.decorator';
import { RefreshMobileSessionUseCase } from './usecases/refresh-mobile-session.usecase';
import { UserDatabaseRepository } from '@/modules/users';
import { SessionTokenService } from './services/session-token.service';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { right } from '@/shared/core/either';

const SECRET = 'http-refresh-regression-secret-only';

@Controller('auth')
class RefreshHttpHarness {
  constructor(private readonly refresh: RefreshMobileSessionUseCase) {}

  @PostAuth('refresh')
  @AllowTokenTypes(JwtTokenType.REFRESH)
  async rotate(@CurrentUser() user: AuthUser) {
    const result = await this.refresh.execute(user);
    if (result.isLeft()) throw result.value;
    return result.value;
  }

  @PostAuth('protected')
  async protectedRoute(@CurrentUser() user: AuthUser) {
    return { userId: user.userId };
  }
}

describe('refresh-token replay over the guarded HTTP boundary', () => {
  let module: TestingModule;
  let app: ReturnType<TestingModule['createNestApplication']>;
  let sessions: SessionTokenService;
  let jwt: JwtService;
  let origin: string;

  const entries = new Map<string, { value: string; expiresAt: number }>();
  const redis = {
    add: async (key: string, value: string, ttlSeconds?: number): Promise<void> => {
      entries.set(key, { value, expiresAt: Date.now() + (ttlSeconds ?? 0) * 1000 });
    },
    setIfAbsent: async (key: string, value: string, ttlSeconds: number): Promise<boolean> => {
      const current = entries.get(key);
      if (current && current.expiresAt > Date.now()) return false;
      await redis.add(key, value, ttlSeconds);
      return true;
    },
    get: async (key: string): Promise<string | null> => {
      const current = entries.get(key);
      if (!current || current.expiresAt <= Date.now()) return null;
      return current.value;
    },
    exists: async (key: string): Promise<boolean> => (await redis.get(key)) !== null,
    del: async (key: string): Promise<void> => { entries.delete(key); },
  };

  const post = async (path: string, token: string) => fetch(`${origin}${path}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
  });

  beforeAll(async () => {
    const config = {
      getOrThrow: (key: string): string => {
        if (key === 'JWT_SECRET') return SECRET;
        throw new Error(`Unexpected required config key ${key}`);
      },
      get: (key: string, fallback?: string): string | undefined => {
        if (key === 'JWT_EXPIRES_IN') return '15m';
        if (key === 'JWT_REFRESH_EXPIRES_IN') return '7d';
        if (key === 'JWT_BIOMETRIC_EXPIRES_IN') return '7d';
        return fallback;
      },
    };
    const user = {
      id: 'http-refresh-user',
      role: UserRole.USER,
      suspendedAt: null,
      suspensionReason: null,
    };
    module = await Test.createTestingModule({
      imports: [JwtModule.register({ secret: SECRET })],
      controllers: [RefreshHttpHarness],
      providers: [
        RefreshMobileSessionUseCase,
        SessionTokenService,
        SessionRevokerService,
        JwtTokenValidatorService,
        JwtAuthGuard,
        { provide: UserDatabaseRepository, useValue: { findById: async () => right(user) } },
        { provide: ConfigService, useValue: config },
        { provide: RedisService, useValue: redis },
        { provide: AuthSessionStateDatabaseRepository, useValue: { findInvalidBefore: async () => null, advanceInvalidBefore: async () => undefined } },
        { provide: APP_GUARD, useClass: JwtAuthGuard },
      ],
    }).compile();
    app = module.createNestApplication();
    await app.init();
    await app.listen(0);
    const address = app.getHttpServer().address();
    if (!address || typeof address === 'string') throw new Error('HTTP test server did not bind');
    origin = `http://127.0.0.1:${address.port}`;
    sessions = module.get(SessionTokenService);
    jwt = module.get(JwtService);
  });

  afterAll(async () => {
    await app.close();
    entries.clear();
  });

  it('revokes the rotated token family when the blacklisted refresh token is replayed', async () => {
    const original = sessions.generate(userId, UserRole.USER, Date.now(), 'replay-family', Date.now());
    const firstRefresh = await post('/auth/refresh', original.refreshToken);
    expect(firstRefresh.status).toBe(201);
    const rotated = await firstRefresh.json() as { token: string; refreshToken: string };
    expect((await post('/auth/protected', rotated.token)).status).toBe(201);

    expect((await post('/auth/refresh', original.refreshToken)).status).toBe(401);
    expect((await post('/auth/protected', rotated.token)).status).toBe(401);
  });

  it('does not revoke another family for malformed, wrong-type, or revoked access tokens', async () => {
    const unrelated = sessions.generate(userId, UserRole.USER, Date.now(), 'unrelated-family', Date.now());
    const accessPayload = await jwt.verifyAsync<JwtPayload>(unrelated.token, { secret: SECRET });
    await sessions.revoke(accessPayload.jti, accessPayload.exp);

    expect((await post('/auth/refresh', 'not-a-jwt')).status).toBe(401);
    expect((await post('/auth/refresh', unrelated.token)).status).toBe(401);
    expect((await post('/auth/protected', unrelated.token)).status).toBe(401);

    const stillValid = await post('/auth/refresh', unrelated.refreshToken);
    expect(stillValid.status).toBe(201);
    const rotated = await stillValid.json() as { token: string };
    expect((await post('/auth/protected', rotated.token)).status).toBe(201);
  });
});

const userId = 'http-refresh-user';
