import { Test, TestingModule } from '@nestjs/testing';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { right } from '@/shared/core/either';
import { AuthUser, JwtTokenType } from '@/shared/core/types';
import { UserRole } from '@prisma/client';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { SessionRevokerService, SESSION_INVALID_BEFORE_PREFIX } from '@/shared/auth/session-revoker.service';
import { UserDatabaseRepository } from '@/modules/users';
import { PasswordRecoveryDatabaseRepository } from './data/repositories/password-recovery-database.repository';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';
import { SessionTokenService } from './services/session-token.service';
import { LoginUseCase } from './usecases/login.usecase';
import { ResetPasswordUseCase } from './usecases/reset-password.usecase';
import { RefreshMobileSessionUseCase } from './usecases/refresh-mobile-session.usecase';
import { BiometricLoginUseCase } from './usecases/biometric-login.usecase';
import { BiometricCredentialService } from '@/shared/auth/biometric-credential.service';

const SECRET = 'synthetic-password-reset-race-secret';
const originalHash = 'synthetic-old-password-hash';
jest.mock('bcryptjs');
const entries = new Map<string, { value: string; expiresAt: number }>();
const redis = {
  add: async (key: string, value: string, ttlSeconds?: number): Promise<void> => {
    entries.set(key, { value, expiresAt: Date.now() + (ttlSeconds ?? 0) * 1000 });
  },
  setIfAbsent: async (key: string, value: string, ttlSeconds: number): Promise<boolean> => {
    const existing = entries.get(key);
    if (existing && existing.expiresAt > Date.now()) return false;
    await redis.add(key, value, ttlSeconds);
    return true;
  },
  exists: async (key: string): Promise<boolean> => {
    const existing = entries.get(key);
    return existing !== undefined && existing.expiresAt > Date.now();
  },
  get: async (key: string): Promise<string | null> => entries.get(key)?.value ?? null,
  del: async (key: string): Promise<void> => { entries.delete(key); },
};

describe('login/password-reset race owner-review gate', () => {
  let module: TestingModule;
  let login: LoginUseCase;
  let reset: ResetPasswordUseCase;
  let validator: JwtTokenValidatorService;
  let sessions: SessionTokenService;
  let refreshMobile: RefreshMobileSessionUseCase;
  let biometricLogin: BiometricLoginUseCase;
  let loginProofReached: () => void;
  let continueLogin: () => void;
  let loginProofGate: Promise<void>;
  let releaseLogin: Promise<void>;
  let passwordHash = originalHash;
  let durableCutoff: Date | null = null;
  let userLookupGate: Promise<void> = Promise.resolve();
  let userLookupStarted: () => void = () => undefined;
  let releaseUserLookup: () => void = () => undefined;
  let userLookupReached: Promise<void> = Promise.resolve();

  beforeAll(async () => {
    const user = {
      id: 'race-user', email: 'synthetic@example.invalid', displayName: 'Synthetic',
      username: null, passwordHash: originalHash, role: UserRole.USER,
      suspendedAt: null, suspensionReason: null, isVerified: false,
      reputationScore: 0, totalReviews: 0, createdAt: new Date(),
      avatarUrl: null, avatarBlurHash: null, bannerUrl: null, bio: null,
      city: null, state: null, cpf: null, deletionRequestedAt: null,
    };
    const users = {
      findByEmail: async () => right({ ...user, passwordHash }),
      findById: async () => {
        userLookupStarted();
        await userLookupGate;
        return right({ ...user, passwordHash });
      },
    };
    const recovery = {
      findLatestByEmail: async () => right({
        id: 'recovery-race', userId: user.id, usedAt: null,
        expiresAt: new Date(Date.now() + 60_000), codeHash: 'synthetic-recovery-hash',
      }),
      reserveAttempt: async () => right(true),
      consumeAndUpdatePassword: async (_id: string, _userId: string, nextHash: string) => {
        passwordHash = nextHash;
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
      providers: [
        LoginUseCase, ResetPasswordUseCase, RefreshMobileSessionUseCase, BiometricLoginUseCase,
        SessionTokenService, SessionRevokerService, JwtTokenValidatorService,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: PasswordRecoveryDatabaseRepository, useValue: recovery },
        { provide: ConfigService, useValue: config },
        { provide: RedisService, useValue: redis },
        { provide: AuthSessionStateDatabaseRepository, useValue: {
          findInvalidBefore: async () => durableCutoff,
          advanceInvalidBefore: async (_userId: string, cutoff: Date) => { durableCutoff = cutoff; },
        } },
        { provide: BiometricCredentialService, useValue: { verifyAndConsume: async () => true } },
      ],
    }).compile();
    login = module.get(LoginUseCase);
    reset = module.get(ResetPasswordUseCase);
    validator = module.get(JwtTokenValidatorService);
    sessions = module.get(SessionTokenService);
    refreshMobile = module.get(RefreshMobileSessionUseCase);
    biometricLogin = module.get(BiometricLoginUseCase);
  });

  beforeEach(() => {
    passwordHash = originalHash;
    durableCutoff = null;
    userLookupGate = Promise.resolve();
    userLookupStarted = () => undefined;
    releaseUserLookup = () => undefined;
    userLookupReached = Promise.resolve();
    entries.clear();
    loginProofGate = new Promise<void>((resolve) => { loginProofReached = resolve; });
    releaseLogin = new Promise<void>((resolve) => { continueLogin = resolve; });
    jest.mocked(bcrypt.hash).mockImplementation(async () => 'synthetic-new-password-hash');
    jest.mocked(bcrypt.compare).mockImplementation(async (value, hash) => {
      if (value === 'current-password') {
        loginProofReached();
        await releaseLogin;
        return hash === originalHash;
      }
      if (value === 'new-password-123') return hash === 'synthetic-new-password-hash';
      return value === 'recovery-code' && hash === 'synthetic-recovery-hash';
    });
  });

  afterEach(() => jest.clearAllMocks());
  afterAll(async () => module.close());

  it('rejects a session issued after password reset from a login that began before reset', async () => {
    const loginPromise = login.execute({ email: 'synthetic@example.invalid', password: 'current-password' });
    await loginProofGate;

    const resetResult = await reset.execute({
      email: 'synthetic@example.invalid', code: 'recovery-code', newPassword: 'new-password-123',
    });
    expect(resetResult.isRight()).toBe(true);
    const cutoff = Number(entries.get(`${SESSION_INVALID_BEFORE_PREFIX}race-user`)?.value);
    while (Date.now() <= cutoff) await new Promise<void>((resolve) => setTimeout(resolve, 1));

    continueLogin();
    const loginResult = await loginPromise;
    expect(loginResult.isRight()).toBe(true);
    if (!loginResult.isRight()) return;
    await expect(validator.verifyAndValidate<AuthUser>(loginResult.value.token, [JwtTokenType.ACCESS])).rejects.toThrow();
  });

  it('accepts a fresh login that begins after password reset', async () => {
    await reset.execute({ email: 'synthetic@example.invalid', code: 'recovery-code', newPassword: 'new-password-123' });
    const cutoff = durableCutoff?.getTime();
    if (cutoff === undefined) throw new Error('Password reset did not persist a session cutoff');
    while (Date.now() <= cutoff) await new Promise<void>((resolve) => setTimeout(resolve, 1));
    const loginResult = await login.execute({ email: 'synthetic@example.invalid', password: 'new-password-123' });

    expect(loginResult.isRight()).toBe(true);
    if (!loginResult.isRight()) return;
    await expect(validator.verifyAndValidate<AuthUser>(loginResult.value.token, [JwtTokenType.ACCESS]))
      .resolves.toHaveProperty('sessionStartedAtMs');
  });

  it('carries a previously validated refresh origin through a delayed rotation', async () => {
    const parent = sessions.generate('race-user', UserRole.USER, Date.now(), 'refresh-race', Date.now());
    const parentPayload = await validator.verifyAndValidate<AuthUser>(parent.refreshToken, [JwtTokenType.REFRESH]);
    userLookupReached = new Promise<void>((resolve) => { userLookupStarted = resolve; });
    userLookupGate = new Promise<void>((resolve) => { releaseUserLookup = resolve; });
    const rotation = refreshMobile.execute(parentPayload);
    await userLookupReached;

    await reset.execute({ email: 'synthetic@example.invalid', code: 'recovery-code', newPassword: 'new-password-123' });
    releaseUserLookup();
    const result = await rotation;

    expect(result.isRight()).toBe(true);
    if (!result.isRight()) return;
    await expect(validator.verifyAndValidate<AuthUser>(result.value.token, [JwtTokenType.ACCESS])).rejects.toThrow('Sessão expirada');
  });

  it('carries a previously validated biometric origin through a delayed login rotation', async () => {
    const biometric = sessions.generateBiometric('race-user', UserRole.USER, 'biometric-race', Date.now());
    userLookupReached = new Promise<void>((resolve) => { userLookupStarted = resolve; });
    userLookupGate = new Promise<void>((resolve) => { releaseUserLookup = resolve; });
    const rotation = biometricLogin.execute({ biometricToken: biometric, challengeId: 'challenge', signature: 'signature' });
    await userLookupReached;

    await reset.execute({ email: 'synthetic@example.invalid', code: 'recovery-code', newPassword: 'new-password-123' });
    releaseUserLookup();
    const result = await rotation;

    expect(result.isRight()).toBe(true);
    if (!result.isRight()) return;
    await expect(validator.verifyAndValidate<AuthUser>(result.value.token, [JwtTokenType.ACCESS])).rejects.toThrow('Sessão expirada');
  });
});
