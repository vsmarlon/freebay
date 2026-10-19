import { Body, Controller, HttpCode } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { APP_GUARD } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { PostAuth, PostPublic, CurrentUser } from '@/shared/decorators';
import { AuthUser } from '@/shared/core/types';
import { right } from '@/shared/core/either';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { SessionRevokerService, SESSION_INVALID_BEFORE_PREFIX } from '@/shared/auth/session-revoker.service';
import { UserDatabaseRepository } from '@/modules/users';
import { PasswordRecoveryDatabaseRepository } from './data/repositories/password-recovery-database.repository';
import { SessionTokenService } from './services/session-token.service';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';
import { ResetPasswordDTO } from './dtos/password-recovery.dto';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';

const SECRET = 'synthetic-reset-cutoff-http-secret';
let passwordChanged = false;

@Controller('auth')
class ResetHttpHarness {
  constructor(private readonly resetPassword: ResetPasswordUseCase) {}

  @PostPublic('reset-password')
  @HttpCode(200)
  async reset(@Body() body: ResetPasswordDTO) {
    const result = await this.resetPassword.execute(body);
    if (result.isLeft()) throw result.value;
    return { reset: true };
  }

  @PostAuth('protected')
  async protected(@CurrentUser() user: AuthUser) {
    return { userId: user.userId };
  }
}

describe('temporary password reset invalidation boundary', () => {
  let module: TestingModule;
  let app: ReturnType<TestingModule['createNestApplication']>;
  let origin: string;
  let sessions: SessionTokenService;
  let durableCutoff: Date | null = null;
  const values = new Map<string, string>();
  const redis = {
    add: async (key: string, value: string): Promise<void> => {
      if (key.startsWith(SESSION_INVALID_BEFORE_PREFIX)) throw new Error('synthetic Redis unavailable');
      values.set(key, value);
    },
    setIfAbsent: async (): Promise<boolean> => true,
    exists: async (key: string): Promise<boolean> => values.has(key),
    get: async (key: string): Promise<string | null> => values.get(key) ?? null,
    del: async (key: string): Promise<void> => { values.delete(key); },
  };

  beforeAll(async () => {
    const now = new Date();
    const recoveryCodeHash = await bcrypt.hash('123456', 4);
    const user = {
      id: 'reset-http-user', email: 'synthetic@example.invalid', displayName: 'Synthetic',
      username: null, passwordHash: 'old-password-hash', role: UserRole.USER,
      suspendedAt: null, suspensionReason: null, isVerified: false,
      reputationScore: 0, totalReviews: 0, createdAt: now,
      avatarUrl: null, avatarBlurHash: null, bannerUrl: null, bio: null,
      city: null, state: null, cpf: null, deletionRequestedAt: null,
    };
    const users = { findByEmail: async () => right(user) };
    const recovery = {
      findLatestByEmail: async () => right({
        id: 'recovery-1', userId: user.id, usedAt: null,
        expiresAt: new Date(Date.now() + 60_000), codeHash: recoveryCodeHash,
      }),
      reserveAttempt: async () => right(true),
      consumeAndUpdatePassword: async (): Promise<ReturnType<typeof right<boolean>>> => {
        passwordChanged = true;
        durableCutoff = new Date();
        return right(true);
      },
    };
    const config = {
      getOrThrow: (key: string): string => key === 'JWT_SECRET' ? SECRET : (() => { throw new Error(key); })(),
      get: (key: string, fallback?: string): string | undefined => key === 'JWT_EXPIRES_IN' ? '15m'
        : key === 'JWT_REFRESH_EXPIRES_IN' || key === 'JWT_BIOMETRIC_EXPIRES_IN' ? '7d' : fallback,
    };
    module = await Test.createTestingModule({
      imports: [JwtModule.register({ secret: SECRET })],
      controllers: [ResetHttpHarness],
      providers: [
        ResetPasswordUseCase, SessionTokenService, SessionRevokerService, JwtTokenValidatorService, JwtAuthGuard,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: PasswordRecoveryDatabaseRepository, useValue: recovery },
        { provide: ConfigService, useValue: config },
        { provide: RedisService, useValue: redis },
        { provide: AuthSessionStateDatabaseRepository, useValue: {
          findInvalidBefore: async () => durableCutoff,
          advanceInvalidBefore: async (_userId: string, cutoff: Date) => { durableCutoff = cutoff; },
        } },
        { provide: APP_GUARD, useClass: JwtAuthGuard },
      ],
    }).compile();
    app = module.createNestApplication();
    await app.init();
    await app.listen(0);
    const address = app.getHttpServer().address();
    if (!address || typeof address === 'string') throw new Error('Test HTTP server did not bind');
    origin = `http://127.0.0.1:${address.port}`;
    sessions = module.get(SessionTokenService);
  });

  afterAll(async () => app.close());

  it('commits password change but refuses to leave the prior access token valid when Redis fails', async () => {
    passwordChanged = false;
    durableCutoff = null;
    values.clear();
    const oldTokens = sessions.generate('reset-http-user', UserRole.USER, Date.now(), undefined, Date.now());
    const resetResponse = await fetch(`${origin}/auth/reset-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'synthetic@example.invalid', code: '123456', newPassword: 'new-password-123' }),
    });
    const protectedResponse = await fetch(`${origin}/auth/protected`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${oldTokens.token}` },
    });

    expect({ resetStatus: resetResponse.status, passwordChanged, oldAccessStatus: protectedResponse.status })
      .toEqual({ resetStatus: 200, passwordChanged: true, oldAccessStatus: 401 });
  });
});
