import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { SessionTokenService } from './session-token.service';
import { UserRole } from '@prisma/client';

describe('SessionTokenService', () => {
  it('keeps biometric issuance separate from normal sessions', async () => {
    const jwt = { sign: jest.fn().mockReturnValue('jwt') };
    const config = { get: jest.fn().mockReturnValue('7d') };
    const redis = { setIfAbsent: jest.fn().mockResolvedValue(true) };
    const module = await Test.createTestingModule({
      providers: [
        SessionTokenService,
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: config },
        { provide: RedisService, useValue: redis },
      ],
    }).compile();

    const service = module.get(SessionTokenService);

    expect(service.generate('user-1', UserRole.USER)).toEqual({
      token: 'jwt',
      refreshToken: 'jwt',
    });
    expect(service.generateBiometric('user-1', UserRole.USER)).toBe('jwt');
  });
});
