import * as bcrypt from 'bcryptjs';
import { UserDatabaseRepository } from '@/modules/users';
import { PasswordRecoveryDatabaseRepository } from '../data/repositories/password-recovery-database.repository';
import { RecoveryCodeNotFoundError } from '@/shared/core/errors';
import { ResetPasswordUseCase } from './reset-password.usecase';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { right } from '@/shared/core/either';

describe('ResetPasswordUseCase', () => {
  let sut: ResetPasswordUseCase;
  let userRepository: jest.Mocked<Partial<UserDatabaseRepository>>;
  let recoveryRepository: jest.Mocked<Partial<PasswordRecoveryDatabaseRepository>>;
  let sessionRevoker: jest.Mocked<Partial<SessionRevokerService>>;

  beforeEach(() => {
    jest.clearAllMocks();
    userRepository = {
      findByEmail: jest.fn(),
      update: jest.fn(),
    };
    recoveryRepository = {
      findLatestByEmail: jest.fn(),
      reserveAttempt: jest.fn().mockResolvedValue(right(true)),
      consumeAndUpdatePassword: jest.fn(),
    };
    sessionRevoker = {
      revokeAllSessions: jest.fn(),
    };

    sut = new ResetPasswordUseCase(
      userRepository as UserDatabaseRepository,
      recoveryRepository as PasswordRecoveryDatabaseRepository,
      sessionRevoker as SessionRevokerService,
    );
  });

  it('resets password and marks code as used when code is valid', async () => {
    const codeHash = await bcrypt.hash('123456', 10);

    recoveryRepository.findLatestByEmail = jest.fn().mockResolvedValue(right({
      id: 'recovery-1',
      codeHash,
      usedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
    }));
    userRepository.findByEmail = jest.fn().mockResolvedValue(right({ id: 'user-1' }));
    recoveryRepository.consumeAndUpdatePassword = jest.fn().mockResolvedValue(right(true));

    const result = await sut.execute({
      email: 'user@test.com',
      code: '123456',
      newPassword: 'newpassword123',
    });

    expect(result.isRight()).toBe(true);
    expect(recoveryRepository.consumeAndUpdatePassword).toHaveBeenCalledWith(
      'recovery-1', 'user-1', expect.any(String),
    );
    expect(sessionRevoker.revokeAllSessions).toHaveBeenCalledWith('user-1');
  });

  it('returns left(RecoveryCodeNotFoundError) when recovery code is not found', async () => {
    recoveryRepository.findLatestByEmail = jest.fn().mockResolvedValue(right(null));

    const result = await sut.execute({
      email: 'user@test.com',
      code: '123456',
      newPassword: 'newpassword123',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(RecoveryCodeNotFoundError);
    }
    expect(userRepository.update).not.toHaveBeenCalled();
  });

  it('allows only one concurrent reset with the same recovery code', async () => {
    const codeHash = await bcrypt.hash('123456', 4);
    recoveryRepository.findLatestByEmail = jest.fn().mockResolvedValue(right({
      id: 'recovery-race', codeHash, usedAt: null, expiresAt: new Date(Date.now() + 60_000),
    }));
    userRepository.findByEmail = jest.fn().mockResolvedValue(right({ id: 'user-1' }));
    let consumed = false;
    recoveryRepository.consumeAndUpdatePassword = jest.fn().mockImplementation(async () => {
      if (consumed) return right(false);
      consumed = true;
      return right(true);
    });

    const inputs = { email: 'user@test.com', code: '123456', newPassword: 'newpassword123' };
    const results = await Promise.all([sut.execute(inputs), sut.execute(inputs)]);

    expect(results.filter((result) => result.isRight())).toHaveLength(1);
    expect(recoveryRepository.consumeAndUpdatePassword).toHaveBeenCalledTimes(2);
  });

  it('rejects web-only recovery credentials on the legacy six-digit reset route', async () => {
    recoveryRepository.findLatestByEmail = jest.fn().mockResolvedValue(right({
      id: 'web-reset', codeHash: `web-reset:${'a'.repeat(64)}`, usedAt: null, expiresAt: new Date(Date.now() + 60_000),
    }));
    const result = await sut.execute({ email: 'user@test.com', code: '123456', newPassword: 'newpassword123' });

    expect(result.isLeft()).toBe(true);
    expect(userRepository.findByEmail).not.toHaveBeenCalled();
    expect(recoveryRepository.reserveAttempt).not.toHaveBeenCalled();
    expect(recoveryRepository.consumeAndUpdatePassword).not.toHaveBeenCalled();
  });
});
