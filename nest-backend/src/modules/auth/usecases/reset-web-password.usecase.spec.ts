import { Test } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { ResetWebPasswordUseCase } from './reset-web-password.usecase';

describe('ResetWebPasswordUseCase', () => {
  it('consumes only web-reset credentials and revokes sessions after password update', async () => {
    const recovery = { findByCodeHash: jest.fn().mockResolvedValue(right({ id: 'r1', userId: 'u1', usedAt: null, expiresAt: new Date(Date.now() + 60_000), codeHash: 'web-reset:hash' })), reserveAttempt: jest.fn().mockResolvedValue(right(true)), consumeAndUpdatePassword: jest.fn().mockResolvedValue(right(true)) };
    const revoker = { revokeAllSessions: jest.fn().mockResolvedValue(undefined) };
    const module = await Test.createTestingModule({ providers: [ResetWebPasswordUseCase, { provide: PasswordRecoveryDatabaseRepository, useValue: recovery }, { provide: SessionRevokerService, useValue: revoker }] }).compile();
    const result = await module.get(ResetWebPasswordUseCase).execute({ token: 'A'.repeat(43), newPassword: 'updated-password' });
    expect(result.isRight()).toBe(true);
    expect(recovery.consumeAndUpdatePassword).toHaveBeenCalledWith('r1', 'u1', expect.any(String));
    expect(revoker.revokeAllSessions).toHaveBeenCalledWith('u1');
  });

  it('does not update a password or revoke sessions when the token was already consumed', async () => {
    const recovery = { findByCodeHash: jest.fn().mockResolvedValue(right(null)), reserveAttempt: jest.fn(), consumeAndUpdatePassword: jest.fn() };
    const revoker = { revokeAllSessions: jest.fn() };
    const module = await Test.createTestingModule({ providers: [ResetWebPasswordUseCase, { provide: PasswordRecoveryDatabaseRepository, useValue: recovery }, { provide: SessionRevokerService, useValue: revoker }] }).compile();
    const result = await module.get(ResetWebPasswordUseCase).execute({ token: 'B'.repeat(43), newPassword: 'updated-password' });
    expect(result.isLeft()).toBe(true);
    expect(recovery.consumeAndUpdatePassword).not.toHaveBeenCalled();
    expect(revoker.revokeAllSessions).not.toHaveBeenCalled();
  });

  it('rejects legacy six-digit recovery values before looking up a web credential', async () => {
    const recovery = { findByCodeHash: jest.fn(), reserveAttempt: jest.fn(), consumeAndUpdatePassword: jest.fn() };
    const revoker = { revokeAllSessions: jest.fn() };
    const module = await Test.createTestingModule({ providers: [ResetWebPasswordUseCase, { provide: PasswordRecoveryDatabaseRepository, useValue: recovery }, { provide: SessionRevokerService, useValue: revoker }] }).compile();
    const result = await module.get(ResetWebPasswordUseCase).execute({ token: '123456', newPassword: 'updated-password' });
    expect(result.isLeft()).toBe(true);
    expect(recovery.findByCodeHash).not.toHaveBeenCalled();
  });
});
