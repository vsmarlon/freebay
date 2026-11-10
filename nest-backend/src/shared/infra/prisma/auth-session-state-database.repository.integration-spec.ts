import { JwtModule, JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { ProductStatus } from '@prisma/client';
import { UnauthorizedException } from '@nestjs/common';
import { prisma } from '../../../../test/setup-integration';
import { ProductFactory } from '../../../../test/factories';
import { JwtTokenType } from '@/shared/core/types';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { PrismaService } from './prisma.service';
import { AuthSessionStateDatabaseRepository } from './auth-session-state-database.repository';
import { PasswordRecoveryDatabaseRepository } from '@/modules/auth/data/repositories/password-recovery-database.repository';
import { AccountLifecycleDatabaseRepository } from '@/modules/users/data/repositories/account-lifecycle-database.repository';

const JWT_SECRET = 'synthetic-auth-session-integration-secret-only';

describe('AuthSessionStateDatabaseRepository integration', () => {
  let module: TestingModule;
  let jwt: JwtService;
  let validator: JwtTokenValidatorService;
  let authSessionState: AuthSessionStateDatabaseRepository;
  let passwordRecovery: PasswordRecoveryDatabaseRepository;
  let accountLifecycle: AccountLifecycleDatabaseRepository;

  beforeAll(async () => {
    const emptyRedisCache = {
      exists: async (_key: string): Promise<boolean> => false,
      get: async (_key: string): Promise<string | null> => null,
      add: async (_key: string, _value: string, _ttlSeconds?: number): Promise<void> => undefined,
      del: async (_key: string): Promise<void> => undefined,
    };
    module = await Test.createTestingModule({
      imports: [JwtModule.register({ secret: JWT_SECRET })],
      providers: [
        AuthSessionStateDatabaseRepository,
        PasswordRecoveryDatabaseRepository,
        AccountLifecycleDatabaseRepository,
        JwtTokenValidatorService,
        SessionRevokerService,
        { provide: PrismaService, useValue: prisma },
        { provide: RedisService, useValue: emptyRedisCache },
        { provide: ConfigService, useValue: { getOrThrow: (key: string) => key === 'JWT_SECRET' ? JWT_SECRET : undefined } },
      ],
    }).compile();
    jwt = module.get(JwtService);
    validator = module.get(JwtTokenValidatorService);
    authSessionState = module.get(AuthSessionStateDatabaseRepository);
    passwordRecovery = module.get(PasswordRecoveryDatabaseRepository);
    accountLifecycle = module.get(AccountLifecycleDatabaseRepository);
  });

  afterAll(async () => module.close());

  it('validates JWTs against the durable cutoff with an empty Redis cache and never moves the cutoff backward', async () => {
    const user = await prisma.user.create({ data: { email: `durable-cutoff-${Date.now()}@example.invalid`, displayName: 'Durable cutoff' } });
    const cutoff = new Date(Math.floor((Date.now() - 5_000) / 1000) * 1000);
    const oldToken = await jwt.signAsync({ userId: user.id, type: JwtTokenType.ACCESS, iat: Math.floor((cutoff.getTime() - 1000) / 1000) });

    expect(await authSessionState.findInvalidBefore(user.id)).toBeNull();
    await expect(validator.verifyAndValidate<{ userId: string }>(oldToken)).resolves.toMatchObject({ userId: user.id });

    await authSessionState.advanceInvalidBefore(user.id, cutoff);
    await authSessionState.advanceInvalidBefore(user.id, new Date(cutoff.getTime() - 2000));

    expect(await authSessionState.findInvalidBefore(user.id)).toEqual(cutoff);
    await expect(validator.verifyAndValidate<{ userId: string }>(oldToken)).rejects.toBeInstanceOf(UnauthorizedException);
    const freshToken = await jwt.signAsync({ userId: user.id, type: JwtTokenType.ACCESS, iat: Math.floor((cutoff.getTime() + 1000) / 1000) });
    await expect(validator.verifyAndValidate<{ userId: string }>(freshToken)).resolves.toMatchObject({ userId: user.id });
  });

  it('commits password replacement, recovery-code consumption, and the durable cutoff together', async () => {
    const user = await prisma.user.create({ data: { email: `durable-reset-${Date.now()}@example.invalid`, displayName: 'Durable reset', passwordHash: 'old-synthetic-hash' } });
    const recovery = await prisma.passwordRecoveryCode.create({ data: {
      userId: user.id,
      codeHash: 'synthetic-recovery-hash',
      expiresAt: new Date(Date.now() + 60_000),
      maxAttempts: 5,
    } });

    const result = await passwordRecovery.consumeAndUpdatePassword(recovery.id, user.id, 'new-synthetic-hash');

    expect(result.isRight() && result.value).toBe(true);
    const persistedUser = await prisma.user.findUniqueOrThrow({ where: { id: user.id } });
    const persistedRecovery = await prisma.passwordRecoveryCode.findUniqueOrThrow({ where: { id: recovery.id } });
    expect(persistedUser.passwordHash).toBe('new-synthetic-hash');
    expect(persistedUser.sessionsInvalidBefore).toEqual(expect.any(Date));
    expect(persistedRecovery.usedAt).toEqual(expect.any(Date));
    expect(await authSessionState.findInvalidBefore(user.id)).toEqual(persistedUser.sessionsInvalidBefore);
  });

  it('persists deletion pause/cutoff and preserves the legacy request cutoff when cancellation clears its date', async () => {
    const user = await prisma.user.create({ data: { email: `durable-delete-${Date.now()}@example.invalid`, displayName: 'Durable deletion' } });
    const product = await new ProductFactory(prisma).create(user.id, { status: ProductStatus.ACTIVE });
    const requestedAt = new Date(Math.floor((Date.now() - 1000) / 1000) * 1000);

    const request = await accountLifecycle.requestDeletion(user.id, requestedAt);
    expect(request.isRight()).toBe(true);
    const requestedUser = await prisma.user.findUniqueOrThrow({ where: { id: user.id } });
    expect(requestedUser.deletionRequestedAt).toEqual(requestedAt);
    expect(requestedUser.sessionsInvalidBefore).toEqual(requestedAt);
    expect((await prisma.product.findUniqueOrThrow({ where: { id: product.id } })).status).toBe(ProductStatus.PAUSED);

    await prisma.user.update({ where: { id: user.id }, data: { sessionsInvalidBefore: null } });
    const cancellation = await accountLifecycle.cancelDeletion(user.id);

    expect(cancellation.isRight()).toBe(true);
    const cancelledUser = await prisma.user.findUniqueOrThrow({ where: { id: user.id } });
    expect(cancelledUser.deletionRequestedAt).toBeNull();
    expect(cancelledUser.sessionsInvalidBefore).toEqual(requestedAt);
  });
});
