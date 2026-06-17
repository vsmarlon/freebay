import * as bcrypt from 'bcryptjs';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { PrismaPasswordRecoveryRepository } from '../repositories/password-recovery.repository';
import { RecoveryCodeNotFoundError } from '@/shared/core/errors';
import { ResetPasswordUseCase } from './reset-password.usecase';
import { RedisService } from '@/shared/infra/redis/redis.service';

describe('ResetPasswordUseCase', () => {
  let sut: ResetPasswordUseCase;
  let userRepository: jest.Mocked<Partial<PrismaUserRepository>>;
  let recoveryRepository: jest.Mocked<Partial<PrismaPasswordRecoveryRepository>>;
  let redisService: jest.Mocked<Partial<RedisService>>;

  beforeEach(() => {
    jest.clearAllMocks();
    userRepository = {
      findByEmail: jest.fn(),
      update: jest.fn(),
    };
    recoveryRepository = {
      findLatestByEmail: jest.fn(),
      markUsed: jest.fn(),
    };
    redisService = {
      add: jest.fn(),
    };

    sut = new ResetPasswordUseCase(
      userRepository as PrismaUserRepository,
      recoveryRepository as PrismaPasswordRecoveryRepository,
      redisService as RedisService,
    );
  });

  it('resets password and marks code as used when code is valid', async () => {
    const codeHash = await bcrypt.hash('123456', 10);

    recoveryRepository.findLatestByEmail = jest.fn().mockResolvedValue({
      id: 'recovery-1',
      codeHash,
      usedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
    });
    userRepository.findByEmail = jest.fn().mockResolvedValue({ id: 'user-1' });
    userRepository.update = jest.fn().mockResolvedValue({ id: 'user-1' });
    recoveryRepository.markUsed = jest.fn().mockResolvedValue({ id: 'recovery-1' });

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
    expect(redisService.add).toHaveBeenCalledWith(
      'user_tokens_invalid_before:user-1',
      expect.any(String),
      2592000,
    );
  });

  it('returns left(RecoveryCodeNotFoundError) when recovery code is not found', async () => {
    recoveryRepository.findLatestByEmail = jest.fn().mockResolvedValue(null);

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
