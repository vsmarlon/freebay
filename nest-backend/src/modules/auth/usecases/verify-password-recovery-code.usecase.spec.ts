import { Test } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { right } from '@/shared/core/either';
import { RecoveryCodeAttemptsExceededError, RecoveryCodeNotFoundError } from '@/shared/core/errors';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { VerifyPasswordRecoveryCodeUseCase } from './verify-password-recovery-code.usecase';

describe('VerifyPasswordRecoveryCodeUseCase attempt budget', () => {
  it('atomically reserves no more than the configured attempts under concurrency', async () => {
    const codeHash = await bcrypt.hash('123456', 4);
    let attempts = 0;
    const recovery = {
      findLatestByEmail: jest.fn().mockResolvedValue(right({
        id: 'recovery-1', codeHash, usedAt: null, expiresAt: new Date(Date.now() + 60_000), attempts: 0, maxAttempts: 5,
      })),
      reserveAttempt: jest.fn().mockImplementation(async () => {
        if (attempts >= 5) return right(false);
        attempts += 1;
        return right(true);
      }),
    };
    const module = await Test.createTestingModule({
      providers: [VerifyPasswordRecoveryCodeUseCase, { provide: PasswordRecoveryDatabaseRepository, useValue: recovery }],
    }).compile();

    const outcomes = await Promise.all(Array.from({ length: 8 }, () => module.get(VerifyPasswordRecoveryCodeUseCase).execute({
      email: 'person@example.com', code: '000000',
    })));

    expect(attempts).toBe(5);
    expect(outcomes.filter((outcome) => outcome.isLeft() && outcome.value instanceof RecoveryCodeAttemptsExceededError)).toHaveLength(3);
  });

  it('does not spend a recovery-link attempt when a six-digit code endpoint receives a web-reset credential', async () => {
    const recovery = {
      findLatestByEmail: jest.fn().mockResolvedValue(right({
        id: 'web-reset-1', codeHash: `web-reset:${'a'.repeat(64)}`, usedAt: null, expiresAt: new Date(Date.now() + 60_000),
      })),
      reserveAttempt: jest.fn().mockResolvedValue(right(true)),
    };
    const module = await Test.createTestingModule({
      providers: [VerifyPasswordRecoveryCodeUseCase, { provide: PasswordRecoveryDatabaseRepository, useValue: recovery }],
    }).compile();

    const result = await module.get(VerifyPasswordRecoveryCodeUseCase).execute({ email: 'person@example.com', code: '123456' });

    expect(result.isLeft() && result.value).toBeInstanceOf(RecoveryCodeNotFoundError);
    expect(recovery.reserveAttempt).not.toHaveBeenCalled();
  });
});
