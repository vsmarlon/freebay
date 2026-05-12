import { ForgotPasswordUseCase } from './forgot-password.usecase';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { EmailService } from '@/shared/infra/email/email.service';

describe('ForgotPasswordUseCase', () => {
  let sut: ForgotPasswordUseCase;
  let userRepository: jest.Mocked<Partial<PrismaUserRepository>>;
  let redisService: jest.Mocked<Partial<RedisService>>;
  let emailService: jest.Mocked<Partial<EmailService>>;

  const mockUser = {
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'User',
    passwordHash: 'hash',
    isGuest: false,
  };

  beforeEach(() => {
    jest.clearAllMocks();
    userRepository = { findByEmail: jest.fn() };
    redisService = { add: jest.fn() };
    emailService = { sendPasswordReset: jest.fn() };

    sut = new ForgotPasswordUseCase(
      userRepository as PrismaUserRepository,
      redisService as RedisService,
      emailService as EmailService,
    );
  });

  it('returns right(void) and sends email when user exists', async () => {
    userRepository.findByEmail = jest.fn().mockResolvedValue(mockUser);
    redisService.add = jest.fn().mockResolvedValue(undefined);
    emailService.sendPasswordReset = jest.fn().mockResolvedValue(undefined);

    const result = await sut.execute({ email: 'user@example.com' });

    expect(result.isRight()).toBe(true);
    expect(redisService.add).toHaveBeenCalledWith(
      expect.stringMatching(/^password_reset:/),
      'user-1',
      900,
    );
    expect(emailService.sendPasswordReset).toHaveBeenCalledWith(
      'user@example.com',
      expect.any(String),
    );
  });

  it('returns right(void) silently when user does NOT exist (no enumeration)', async () => {
    userRepository.findByEmail = jest.fn().mockResolvedValue(null);

    const result = await sut.execute({ email: 'ghost@example.com' });

    expect(result.isRight()).toBe(true);
    expect(emailService.sendPasswordReset).not.toHaveBeenCalled();
  });
});