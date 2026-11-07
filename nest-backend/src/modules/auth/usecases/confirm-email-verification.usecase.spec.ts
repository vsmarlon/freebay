import { Test } from '@nestjs/testing';
import { createHash } from 'node:crypto';
import { UserRole } from '@prisma/client';
import { left, right } from '@/shared/core/either';
import {
  EmailVerificationCodeAttemptsExceededError,
  EmailVerificationCodeNotFoundError,
} from '@/shared/core/errors';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '@/modules/users';
import { ConfirmEmailVerificationUseCase } from './confirm-email-verification.usecase';

describe('ConfirmEmailVerificationUseCase', () => {
  const token = 'raw-verification-token';
  const tokenHash = createHash('sha256').update(token).digest('hex');
  const user = {
    id: 'u1',
    displayName: 'Person',
    username: 'person',
    email: 'person@example.com',
    emailVerified: false,
    avatarUrl: null,
    avatarBlurHash: null,
    bannerUrl: null,
    bio: null,
    city: null,
    state: null,
    isVerified: false,
    role: UserRole.USER,
    reputationScore: 0,
    totalReviews: 0,
    createdAt: new Date('2026-01-15T10:30:00.000Z'),
    deletedAt: null,
    suspendedAt: null,
    cpf: null,
  };

  async function compile(overrides: { users?: object; redis?: object } = {}) {
    const users = {
      findById: jest.fn().mockResolvedValue(right(user)),
      update: jest.fn().mockResolvedValue(right({ ...user, emailVerified: true })),
      ...overrides.users,
    };
    const redis = {
      get: jest.fn().mockResolvedValue(tokenHash),
      incrementWithExpiry: jest.fn().mockResolvedValue(1),
      del: jest.fn().mockResolvedValue(undefined),
      ...overrides.redis,
    };
    const module = await Test.createTestingModule({
      providers: [
        ConfirmEmailVerificationUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: RedisService, useValue: redis },
      ],
    }).compile();
    return { sut: module.get(ConfirmEmailVerificationUseCase), users, redis };
  }

  it('marks the account verified with the safe projection when the token matches', async () => {
    const { sut, users, redis } = await compile();

    const result = await sut.execute('u1', token);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.emailVerified).toBe(true);
      expect(result.value.user.id).toBe('u1');
      expect(JSON.stringify(result.value.user)).not.toContain(tokenHash);
      expect(JSON.stringify(result.value.user)).not.toContain('person@example.com');
    }
    expect(users.update).toHaveBeenCalledWith('u1', { emailVerified: true });
    expect(redis.del).toHaveBeenCalledWith('email-verification:code:u1');
    expect(redis.del).toHaveBeenCalledWith('email-verification:attempts:u1');
  });

  it('rejects a wrong token with the not-found error and keeps the account unverified', async () => {
    const { sut, users } = await compile();

    const result = await sut.execute('u1', 'attacker-guess');

    expect(result).toEqual(left(new EmailVerificationCodeNotFoundError()));
    expect(users.update).not.toHaveBeenCalled();
  });

  it('rejects a consumed or expired challenge as not found', async () => {
    const { sut, users } = await compile({ redis: { get: jest.fn().mockResolvedValue(null) } });

    const result = await sut.execute('u1', token);

    expect(result).toEqual(left(new EmailVerificationCodeNotFoundError()));
    expect(users.update).not.toHaveBeenCalled();
  });

  it('rejects verification once the attempt budget is exhausted', async () => {
    const { sut, users } = await compile({ redis: { incrementWithExpiry: jest.fn().mockResolvedValue(6) } });

    const result = await sut.execute('u1', token);

    expect(result).toEqual(left(new EmailVerificationCodeAttemptsExceededError()));
    expect(users.update).not.toHaveBeenCalled();
  });

  it('counts the attempt before comparing so a wrong guess always consumes one', async () => {
    const getOrder: string[] = [];
    const { sut } = await compile({
      redis: {
        get: jest.fn().mockImplementation(async () => { getOrder.push('get'); return tokenHash; }),
        incrementWithExpiry: jest.fn().mockImplementation(async () => { getOrder.push('attempt'); return 1; }),
        del: jest.fn(),
      },
    });

    await sut.execute('u1', 'attacker-guess');

    expect(getOrder).toEqual(['get', 'attempt']);
  });

  it('rejects an empty token without touching storage beyond the challenge read', async () => {
    const { sut, redis } = await compile();

    const result = await sut.execute('u1', '');

    expect(result).toEqual(left(new EmailVerificationCodeNotFoundError()));
    expect(redis.incrementWithExpiry).not.toHaveBeenCalled();
  });
});
