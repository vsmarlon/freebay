import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { right } from '@/shared/core/either';
import { JwtTokenType } from '@/shared/core/types';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { BiometricLoginUseCase } from './biometric-login.usecase';

describe('BiometricLoginUseCase', () => {
  const payload = {
    userId: 'u1',
    role: 'USER',
    type: JwtTokenType.BIOMETRIC,
    jti: 'biometric-jti',
    exp: Math.floor(Date.now() / 1000) + 60,
    iat: Math.floor(Date.now() / 1000),
  };

  async function createSubject(redis: { get: jest.Mock }) {
    const users = {
      findById: jest.fn().mockResolvedValue(right({ id: 'u1', role: 'USER', suspendedAt: null })),
    };
    const jwt = { verifyAsync: jest.fn().mockResolvedValue(payload) };
    const module = await Test.createTestingModule({
      providers: [
        BiometricLoginUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn().mockReturnValue('secret') } },
        { provide: RedisService, useValue: redis },
      ],
    }).compile();
    return module.get(BiometricLoginUseCase);
  }

  it('validates concurrent biometric requests; replay protection belongs to AuthService', async () => {
    const sut = await createSubject({ get: jest.fn().mockResolvedValue(null) });

    const results = await Promise.all([sut.execute('token'), sut.execute('token')]);

    expect(results.filter((result) => result.isRight())).toHaveLength(2);
  });

  it('rejects an already revoked or claimed token', async () => {
    const sut = await createSubject({ get: jest.fn().mockResolvedValueOnce(null).mockResolvedValueOnce('1') });

    const result = await sut.execute('token');

    expect(result.isLeft()).toBe(true);
  });

  it('checks suspension before claiming the token', async () => {
    const users = {
      findById: jest.fn().mockResolvedValue(right({ id: 'u1', role: 'USER', suspendedAt: new Date(), suspensionReason: 'fraud' })),
    };
    const jwt = { verifyAsync: jest.fn().mockResolvedValue(payload) };
    const module = await Test.createTestingModule({
      providers: [
        BiometricLoginUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn().mockReturnValue('secret') } },
        { provide: RedisService, useValue: { get: jest.fn().mockResolvedValue(null) } },
      ],
    }).compile();

    const result = await module.get(BiometricLoginUseCase).execute('token');

    expect(result.isLeft()).toBe(true);
  });
});
