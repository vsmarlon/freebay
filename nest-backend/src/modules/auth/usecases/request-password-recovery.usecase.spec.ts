import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { createHmac } from 'node:crypto';
import { right } from '@/shared/core/either';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '@/modules/users';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { ResendService } from '../services/resend.service';
import { RequestPasswordRecoveryUseCase } from './request-password-recovery.usecase';

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((resolvePromise) => { resolve = resolvePromise; });
  return { promise, resolve };
}

const nextImmediate = () => new Promise<void>((resolve) => setImmediate(resolve));

describe('RequestPasswordRecoveryUseCase', () => {
  it('normalizes and rate-limits email code issuance without account enumeration', async () => {
    const users = { findByEmail: jest.fn().mockResolvedValue(right(null)) };
    const recovery = { deleteManyForUser: jest.fn(), create: jest.fn(), markSent: jest.fn() };
    const resend = { sendRecoveryCode: jest.fn() };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValue(4), setIfAbsent: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        RequestPasswordRecoveryUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: PasswordRecoveryDatabaseRepository, useValue: recovery },
        { provide: ResendService, useValue: resend },
        { provide: RedisService, useValue: redis },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn().mockReturnValue('test-secret') } },
      ],
    }).compile();

    const result = await module.get(RequestPasswordRecoveryUseCase).execute({ email: ' Person@Example.com ' });

    expect(result.isRight()).toBe(true);
    const emailKey = createHmac('sha256', 'test-secret').update('person@example.com').digest('hex');
    expect(redis.incrementWithExpiry).toHaveBeenCalledWith(`password-recovery:${emailKey}`, 3600);
    expect(users.findByEmail).not.toHaveBeenCalled();
  });

  it('applies a per-email cooldown before looking up or replacing a recovery code', async () => {
    const users = { findByEmail: jest.fn().mockResolvedValue(right({ id: 'u1', email: 'person@example.com' })) };
    const recovery = { deleteManyForUser: jest.fn(), create: jest.fn(), markSent: jest.fn() };
    const resend = { sendRecoveryCode: jest.fn() };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValue(1), setIfAbsent: jest.fn().mockResolvedValue(false) };
    const module = await Test.createTestingModule({
      providers: [
        RequestPasswordRecoveryUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: PasswordRecoveryDatabaseRepository, useValue: recovery },
        { provide: ResendService, useValue: resend },
        { provide: RedisService, useValue: redis },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn().mockReturnValue('test-secret') } },
      ],
    }).compile();

    const result = await module.get(RequestPasswordRecoveryUseCase).execute({ email: 'person@example.com' });

    expect(result.isRight()).toBe(true);
    expect(users.findByEmail).not.toHaveBeenCalled();
    expect(recovery.deleteManyForUser).not.toHaveBeenCalled();
  });

  it('invalidates an undelivered code and releases the cooldown without disclosing delivery status', async () => {
    const emailStarted = deferred<void>();
    const cleanupStarted = deferred<void>();
    const users = { findByEmail: jest.fn().mockResolvedValue(right({ id: 'u1', email: 'person@example.com' })) };
    const recovery = {
      deleteManyForUser: jest.fn().mockResolvedValue(right(undefined)),
      create: jest.fn().mockResolvedValue(right({ id: 'recovery-1' })),
      markSent: jest.fn(),
      delete: jest.fn().mockImplementation(async () => { cleanupStarted.resolve(); return right(undefined); }),
    };
    const resend = { sendRecoveryCode: jest.fn().mockImplementation(async () => { emailStarted.resolve(); return null; }) };
    const redis = {
      incrementWithExpiry: jest.fn().mockResolvedValue(1),
      setIfAbsent: jest.fn().mockResolvedValue(true),
      del: jest.fn().mockResolvedValue(undefined),
    };
    const module = await Test.createTestingModule({
      providers: [
        RequestPasswordRecoveryUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: PasswordRecoveryDatabaseRepository, useValue: recovery },
        { provide: ResendService, useValue: resend },
        { provide: RedisService, useValue: redis },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn().mockReturnValue('test-secret') } },
      ],
    }).compile();

    const result = await module.get(RequestPasswordRecoveryUseCase).execute({ email: 'person@example.com' });
    expect(result.isRight()).toBe(true);
    await emailStarted.promise;
    await cleanupStarted.promise;
    expect(recovery.delete).toHaveBeenCalledWith('recovery-1');
    expect(redis.del).toHaveBeenCalledWith(expect.stringMatching(/^password-recovery-cooldown:/));
  });

  it('returns the same accepted response for an unknown account while its queued lookup is still pending', async () => {
    const lookupStarted = deferred<void>();
    const lookupGate = deferred<void>();
    const users = { findByEmail: jest.fn(async () => {
      lookupStarted.resolve();
      await lookupGate.promise;
      return right(null);
    }) };
    const recovery = { deleteManyForUser: jest.fn(), create: jest.fn(), markSent: jest.fn() };
    const resend = { sendRecoveryCode: jest.fn() };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValue(1), setIfAbsent: jest.fn().mockResolvedValue(true) };
    const module = await Test.createTestingModule({ providers: [
      RequestPasswordRecoveryUseCase,
      { provide: UserDatabaseRepository, useValue: users },
      { provide: PasswordRecoveryDatabaseRepository, useValue: recovery },
      { provide: ResendService, useValue: resend },
      { provide: RedisService, useValue: redis },
      { provide: ConfigService, useValue: { getOrThrow: jest.fn().mockReturnValue('test-secret') } },
    ] }).compile();

    let responseResolved = false;
    const responsePromise = module.get(RequestPasswordRecoveryUseCase).execute({ email: 'absent@example.com' }).then((result) => {
      responseResolved = true;
      return result;
    });
    await nextImmediate();
    const returnedWhileLookupPending = responseResolved;
    await lookupStarted.promise;
    expect(resend.sendRecoveryCode).not.toHaveBeenCalled();
    lookupGate.resolve();
    expect((await responsePromise).isRight()).toBe(true);
    await nextImmediate();
    expect(returnedWhileLookupPending).toBe(true);
  });

  it('returns before known-account persistence and email delivery finish', async () => {
    const lookupStarted = deferred<void>();
    const lookupGate = deferred<void>();
    const emailStarted = deferred<void>();
    const emailGate = deferred<void>();
    const emailDone = deferred<void>();
    const users = { findByEmail: jest.fn(async () => {
      lookupStarted.resolve();
      await lookupGate.promise;
      return right({ id: 'u1', email: 'person@example.com' });
    }) };
    const recovery = {
      deleteManyForUser: jest.fn().mockResolvedValue(right(undefined)),
      create: jest.fn().mockResolvedValue(right({ id: 'recovery-1' })),
      markSent: jest.fn().mockResolvedValue(right({})),
    };
    const resend = { sendRecoveryCode: jest.fn(async () => {
      emailStarted.resolve();
      await emailGate.promise;
      emailDone.resolve();
      return 'email-id';
    }) };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValue(1), setIfAbsent: jest.fn().mockResolvedValue(true) };
    const module = await Test.createTestingModule({ providers: [
      RequestPasswordRecoveryUseCase,
      { provide: UserDatabaseRepository, useValue: users },
      { provide: PasswordRecoveryDatabaseRepository, useValue: recovery },
      { provide: ResendService, useValue: resend },
      { provide: RedisService, useValue: redis },
      { provide: ConfigService, useValue: { getOrThrow: jest.fn().mockReturnValue('test-secret') } },
    ] }).compile();

    let responseResolved = false;
    const responsePromise = module.get(RequestPasswordRecoveryUseCase).execute({ email: 'person@example.com' }).then((result) => {
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
    expect(recovery.create).toHaveBeenCalled();
    expect(resend.sendRecoveryCode).toHaveBeenCalled();
    expect(recovery.create.mock.invocationCallOrder[0]).toBeLessThan(resend.sendRecoveryCode.mock.invocationCallOrder[0]);
    emailGate.resolve();
    await emailDone.promise;
    await nextImmediate();
    expect((await responsePromise).isRight()).toBe(true);
    expect(recovery.markSent).toHaveBeenCalledWith('recovery-1', 'email-id');
    expect(returnedWhileLookupPending).toBe(true);
    expect(returnedWhileEmailPending).toBe(true);
  });

  it('contains queued lookup errors without exposing account-dependent failures', async () => {
    const users = { findByEmail: jest.fn().mockRejectedValue(new Error('private database detail')) };
    const recovery = { deleteManyForUser: jest.fn(), create: jest.fn(), markSent: jest.fn() };
    const resend = { sendRecoveryCode: jest.fn() };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValue(1), setIfAbsent: jest.fn().mockResolvedValue(true) };
    const module = await Test.createTestingModule({ providers: [
      RequestPasswordRecoveryUseCase,
      { provide: UserDatabaseRepository, useValue: users },
      { provide: PasswordRecoveryDatabaseRepository, useValue: recovery },
      { provide: ResendService, useValue: resend },
      { provide: RedisService, useValue: redis },
      { provide: ConfigService, useValue: { getOrThrow: jest.fn().mockReturnValue('test-secret') } },
    ] }).compile();

    const result = await module.get(RequestPasswordRecoveryUseCase).execute({ email: 'person@example.com' });
    expect(result.isRight()).toBe(true);
    await nextImmediate();
    expect(resend.sendRecoveryCode).not.toHaveBeenCalled();
  });
});
