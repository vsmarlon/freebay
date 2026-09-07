import * as bcrypt from 'bcryptjs';
import { UserRepository } from '../domain/repositories/user.repository';
import { PasswordRecoveryRepository } from '../domain/repositories/password-recovery.repository';
import { RecoveryCodeNotFoundError } from '@/shared/core/errors';
import { ResetPasswordUseCase } from './reset-password.usecase';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { right } from '@/shared/core/either';

describe('ResetPasswordUseCase', () => {
  let sut: ResetPasswordUseCase;
  let userRepository: jest.Mocked<Partial<UserRepository>>;
  let recoveryRepository: jest.Mocked<Partial<PasswordRecoveryRepository>>;
  let sessionRevoker: jest.Mocked<Partial<SessionRevokerService>>;

  beforeEach(() => {
    jest.clearAllMocks();
    userRepository = {
      findByEmail: jest.fn(),
      update: jest.fn(),
    };
    recoveryRepository = {
      findLatestByEmail: jest.fn(),
      markUsed: jest.fn(),
    } as jest.Mocked<Partial<PasswordRecoveryRepository>>;
    sessionRevoker = {
      revokeAllSessions: jest.fn(),
    };

    sut = new ResetPasswordUseCase(
      userRepository as UserRepository,
      recoveryRepository as PasswordRecoveryRepository,
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
    userRepository.update = jest.fn().mockResolvedValue(right({ id: 'user-1' }));
    recoveryRepository.markUsed = jest.fn().mockResolvedValue(right({ id: 'recovery-1' }));

    const result = await sut.execute({
      email: 'user@test.com',
      code: '123456',
      newPassword: 'newpassword123',
    });

    expect(result.isRight()).toBe(true);
    expect(userRepository.update).toHaveBeenCalledWith(
      'user-1',
      expect.objectContaining({ passwordHash: expect.any(String) }),
    );
    expect(recoveryRepository.markUsed).toHaveBeenCalledWith('recovery-1');
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
});
