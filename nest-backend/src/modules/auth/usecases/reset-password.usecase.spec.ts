import { ResetPasswordUseCase } from './reset-password.usecase';
import { PrismaUserRepository } from '../repositories/prisma-user.repository';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { InvalidResetTokenError } from '@/shared/core/errors';

describe('ResetPasswordUseCase', () => {
  let sut: ResetPasswordUseCase;
  let userRepository: jest.Mocked<Partial<PrismaUserRepository>>;
  let redisService: jest.Mocked<Partial<RedisService>>;

  const VALID_TOKEN = 'a'.repeat(64);

  beforeEach(() => {
    jest.clearAllMocks();
    userRepository = { update: jest.fn() };
    redisService = {
      get: jest.fn(),
      del: jest.fn(),
    };

    sut = new ResetPasswordUseCase(
      userRepository as PrismaUserRepository,
      redisService as RedisService,
    );
  });

  it('resets password and deletes token when token is valid', async () => {
    redisService.get = jest.fn().mockResolvedValue('user-1');
    userRepository.update = jest.fn().mockResolvedValue({ id: 'user-1' });
    redisService.del = jest.fn().mockResolvedValue(undefined);

    const result = await sut.execute({ token: VALID_TOKEN, password: 'newpassword123' });

    expect(result.isRight()).toBe(true);
    expect(userRepository.update).toHaveBeenCalledWith(
      'user-1',
      expect.objectContaining({ passwordHash: expect.any(String) }),
    );
    expect(redisService.del).toHaveBeenCalledWith(`password_reset:${VALID_TOKEN}`);
  });

  it('returns left(InvalidResetTokenError) when token not found in Redis', async () => {
    redisService.get = jest.fn().mockResolvedValue(null);

    const result = await sut.execute({ token: VALID_TOKEN, password: 'newpassword123' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(InvalidResetTokenError);
    }
    expect(userRepository.update).not.toHaveBeenCalled();
  });
});