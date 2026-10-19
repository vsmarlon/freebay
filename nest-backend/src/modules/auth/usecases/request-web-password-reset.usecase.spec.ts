import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { right } from '@/shared/core/either';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '@/modules/users';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { ResendService } from '../services/resend.service';
import { RequestWebPasswordResetUseCase } from './request-web-password-reset.usecase';

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((resolvePromise) => { resolve = resolvePromise; });
  return { promise, resolve };
}

const nextImmediate = () => new Promise<void>((resolve) => setImmediate(resolve));

describe('RequestWebPasswordResetUseCase', () => {
  function setup(user: { id: string; email: string } | null, sent: string | null = 'email-id') {
    const users = { findByEmail: jest.fn().mockResolvedValue(right(user ? { ...user, passwordHash: 'old-hash' } : null)) };
    const recovery = {
      deleteManyForUser: jest.fn().mockResolvedValue(right(undefined)),
      create: jest.fn().mockImplementation(async (data: { codeHash: string }) => right({ id: 'recovery-1', ...data })),
      markSent: jest.fn().mockResolvedValue(right({})),
      delete: jest.fn().mockResolvedValue(right(undefined)),
    };
    const resend = { sendWebPasswordReset: jest.fn().mockResolvedValue(sent) };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValue(1), setIfAbsent: jest.fn().mockResolvedValue(true), del: jest.fn() };
    const config = { getOrThrow: jest.fn().mockReturnValue('jwt-secret') };
    return Test.createTestingModule({ providers: [
      RequestWebPasswordResetUseCase,
      { provide: UserDatabaseRepository, useValue: users },
      { provide: PasswordRecoveryDatabaseRepository, useValue: recovery },
      { provide: ResendService, useValue: resend },
      { provide: RedisService, useValue: redis },
      { provide: ConfigService, useValue: config },
    ] }).compile().then((module) => ({ usecase: module.get(RequestWebPasswordResetUseCase), users, recovery, resend, redis }));
  }

  it('returns the same success and sends nothing for an unknown account', async () => {
    const { usecase, users, resend } = await setup(null);
    const started = deferred<void>();
    const releaseLookup = deferred<void>();
    users.findByEmail.mockImplementation(async () => {
      started.resolve();
      await releaseLookup.promise;
      return right(null);
    });
    let responseResolved = false;
    const responsePromise = usecase.execute({ email: 'absent@example.com', locale: 'en' }).then((result) => {
      responseResolved = true;
      return result;
    });
    await nextImmediate();
    const returnedWhileLookupPending = responseResolved;
    await started.promise;
    releaseLookup.resolve();
    expect((await responsePromise).isRight()).toBe(true);
    await nextImmediate();
    expect(resend.sendWebPasswordReset).not.toHaveBeenCalled();
    expect(returnedWhileLookupPending).toBe(true);
  });

  it('returns while account lookup and provider delivery are pending, after persisting only a token digest', async () => {
    const { usecase, users, recovery, resend, redis } = await setup({ id: 'u1', email: 'person@example.com' });
    const lookupStarted = deferred<void>();
    const lookupGate = deferred<void>();
    const emailStarted = deferred<void>();
    const emailGate = deferred<void>();
    const emailDone = deferred<void>();
    users.findByEmail.mockImplementation(async () => {
      lookupStarted.resolve();
      await lookupGate.promise;
      return right({ id: 'u1', email: 'person@example.com', passwordHash: 'old-hash' });
    });
    resend.sendWebPasswordReset.mockImplementation(async () => {
      emailStarted.resolve();
      await emailGate.promise;
      emailDone.resolve();
      return 'email-id';
    });

    let responseResolved = false;
    const responsePromise = usecase.execute({ email: 'person@example.com', locale: 'pt-BR' }).then((result) => {
      responseResolved = true;
      return result;
    });
    await nextImmediate();
    const returnedWhileLookupPending = responseResolved;
    await lookupStarted.promise;
    expect(redis.setIfAbsent.mock.invocationCallOrder[0]).toBeLessThan(users.findByEmail.mock.invocationCallOrder[0]);
    lookupGate.resolve();
    await emailStarted.promise;
    const returnedWhileEmailPending = responseResolved;
    const stored = recovery.create.mock.calls[0][0].codeHash;
    expect(stored).toMatch(/^web-reset:[a-f0-9]{64}$/);
    expect(recovery.create.mock.invocationCallOrder[0]).toBeLessThan(resend.sendWebPasswordReset.mock.invocationCallOrder[0]);
    emailGate.resolve();
    await emailDone.promise;
    await nextImmediate();
    expect((await responsePromise).isRight()).toBe(true);
    expect(recovery.markSent).toHaveBeenCalledWith('recovery-1', 'email-id');
    expect(returnedWhileLookupPending).toBe(true);
    expect(returnedWhileEmailPending).toBe(true);
  });

  it('contains queued provider failure without changing the generic request response', async () => {
    const { usecase, recovery, resend, redis } = await setup({ id: 'u1', email: 'person@example.com' });
    resend.sendWebPasswordReset.mockRejectedValue(new Error('provider failure'));
    const responsePromise = usecase.execute({ email: 'person@example.com', locale: 'en' });
    expect((await responsePromise).isRight()).toBe(true);
    await nextImmediate();
    expect(recovery.delete).toHaveBeenCalledWith('recovery-1');
    expect(redis.del).toHaveBeenCalledWith(expect.stringMatching(/^web-password-reset-cooldown:/));
  });

  it('contains queued lookup errors without leaking them through the accepted response', async () => {
    const { usecase, users, resend } = await setup({ id: 'u1', email: 'person@example.com' });
    users.findByEmail.mockRejectedValue(new Error('private database detail'));
    const result = await usecase.execute({ email: 'person@example.com', locale: 'en' });
    expect(result.isRight()).toBe(true);
    await nextImmediate();
    expect(resend.sendWebPasswordReset).not.toHaveBeenCalled();
  });
});
