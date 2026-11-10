import { Test } from '@nestjs/testing';
import { createHash } from 'node:crypto';
import { right } from '@/shared/core/either';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '@/modules/users';
import { ResendService } from '../services/resend.service';
import {
  EMAIL_VERIFICATION_MAX_ATTEMPTS,
  EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS,
  EMAIL_VERIFICATION_RESEND_LIMIT,
  EMAIL_VERIFICATION_RESEND_WINDOW_SECONDS,
  EMAIL_VERIFICATION_TTL_SECONDS,
  RequestEmailVerificationUseCase,
} from './request-email-verification.usecase';

const nextImmediate = () => new Promise<void>((resolve) => setImmediate(resolve));

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((resolvePromise) => { resolve = resolvePromise; });
  return { promise, resolve };
}

describe('RequestEmailVerificationUseCase', () => {
  const user = { id: 'u1', email: 'person@example.com', emailVerified: false };

  async function compile(overrides: { users?: object; redis?: object; resend?: object } = {}) {
    const users = { findById: jest.fn().mockResolvedValue(right(user)), ...overrides.users };
    const redis = {
      incrementWithExpiry: jest.fn().mockResolvedValue(1),
      setIfAbsent: jest.fn().mockResolvedValue(true),
      add: jest.fn().mockResolvedValue(undefined),
      del: jest.fn().mockResolvedValue(undefined),
      ...overrides.redis,
    };
    const resend = { sendMagicLink: jest.fn().mockResolvedValue({ id: 'email-id' }), ...overrides.resend };
    const module = await Test.createTestingModule({
      providers: [
        RequestEmailVerificationUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: RedisService, useValue: redis },
        { provide: ResendService, useValue: resend },
      ],
    }).compile();
    return { sut: module.get(RequestEmailVerificationUseCase), users, redis, resend };
  }

  it('returns the accepted response and sends nothing when the resend window is exhausted', async () => {
    const { sut, redis, users, resend } = await compile({
      redis: { incrementWithExpiry: jest.fn().mockResolvedValue(EMAIL_VERIFICATION_RESEND_LIMIT + 1) },
    });

    const result = await sut.execute('u1', 'en');
    await nextImmediate();

    expect(result).toEqual(right({ sent: true }));
    expect(redis.incrementWithExpiry).toHaveBeenCalledWith('email-verification:requests:u1', EMAIL_VERIFICATION_RESEND_WINDOW_SECONDS);
    expect(redis.add).not.toHaveBeenCalled();
    expect(users.findById).not.toHaveBeenCalled();
    expect(resend.sendMagicLink).not.toHaveBeenCalled();
  });

  it('returns the accepted response and sends nothing while the per-user cooldown is active', async () => {
    const { sut, redis, users, resend } = await compile({
      redis: { setIfAbsent: jest.fn().mockResolvedValue(false) },
    });

    const result = await sut.execute('u1');
    await nextImmediate();

    expect(result).toEqual(right({ sent: true }));
    expect(redis.setIfAbsent).toHaveBeenCalledWith('email-verification:cooldown:u1', '1', EMAIL_VERIFICATION_RESEND_COOLDOWN_SECONDS);
    expect(users.findById).not.toHaveBeenCalled();
    expect(resend.sendMagicLink).not.toHaveBeenCalled();
  });

  it('stores the sha256 hash of the emailed token for ten minutes before returning', async () => {
    const sendStarted = deferred<void>();
    const sendGate = deferred<void>();
    const { sut, redis, resend } = await compile({
      resend: { sendMagicLink: jest.fn(async () => { sendStarted.resolve(); await sendGate.promise; return { id: 'email-id' }; }) },
    });

    let responseResolved = false;
    const response = sut.execute('u1', 'pt-BR').then((result) => { responseResolved = true; return result; });
    await nextImmediate();
    await sendStarted.promise;

    const token: string = resend.sendMagicLink.mock.calls[0]?.[1];
    expect(resend.sendMagicLink).toHaveBeenCalledWith('person@example.com', expect.any(String), 'pt-BR', expect.stringMatching(/^email-verification\//));
    expect(redis.add).toHaveBeenCalledWith('email-verification:code:u1', createHash('sha256').update(token).digest('hex'), EMAIL_VERIFICATION_TTL_SECONDS);
    expect(redis.del).toHaveBeenCalledWith('email-verification:attempts:u1');
    expect(responseResolved).toBe(true);

    sendGate.resolve();
    expect((await response)).toEqual(right({ sent: true }));
  });

  it('does not replace a challenge for an account that is already verified', async () => {
    const { sut, redis, resend } = await compile({
      users: { findById: jest.fn().mockResolvedValue(right({ id: 'u1', email: 'person@example.com', emailVerified: true })) },
    });

    const result = await sut.execute('u1');
    await nextImmediate();

    expect(result).toEqual(right({ sent: true }));
    expect(redis.add).not.toHaveBeenCalled();
    expect(resend.sendMagicLink).not.toHaveBeenCalled();
  });

  it('does not store a challenge for an unknown account', async () => {
    const { sut, redis, resend } = await compile({
      users: { findById: jest.fn().mockResolvedValue(right(null)) },
    });

    const result = await sut.execute('u1');
    await nextImmediate();

    expect(result).toEqual(right({ sent: true }));
    expect(redis.add).not.toHaveBeenCalled();
    expect(resend.sendMagicLink).not.toHaveBeenCalled();
  });

  it.each([
    ['provider rejected the email', { sendMagicLink: jest.fn().mockResolvedValue(null) }],
    ['provider request failed', { sendMagicLink: jest.fn().mockRejectedValue(new Error('network down')) }],
  ])('releases the challenge and cooldown when %s', async (_name, resendOverride) => {
    const { sut, redis } = await compile({ resend: resendOverride });

    const result = await sut.execute('u1');
    await nextImmediate();
    await nextImmediate();

    expect(result).toEqual(right({ sent: true }));
    expect(redis.del).toHaveBeenCalledWith('email-verification:code:u1');
    expect(redis.del).toHaveBeenCalledWith('email-verification:cooldown:u1');
  });

  it('keeps the attempt budget and TTL constants aligned with the consumed challenge', () => {
    // Frozen contract: five guesses per ten-minute challenge, three sends per hour.
    expect(EMAIL_VERIFICATION_MAX_ATTEMPTS).toBe(5);
    expect(EMAIL_VERIFICATION_TTL_SECONDS).toBe(600);
    expect(EMAIL_VERIFICATION_RESEND_LIMIT).toBe(3);
    expect(EMAIL_VERIFICATION_RESEND_WINDOW_SECONDS).toBe(3600);
  });
});
