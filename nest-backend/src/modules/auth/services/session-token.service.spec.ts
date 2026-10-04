import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { SessionTokenService } from './session-token.service';
import { UserRole } from '@prisma/client';

describe('SessionTokenService', () => {
  it('preserves the authentication timestamp in both signed session tokens', async () => {
    const jwt = { sign: jest.fn().mockReturnValue('jwt') };
    const module = await Test.createTestingModule({
      providers: [
        SessionTokenService,
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue('7d') } },
        { provide: RedisService, useValue: { setIfAbsent: jest.fn().mockResolvedValue(true) } },
      ],
    }).compile();

    module.get(SessionTokenService).generate('user-1', UserRole.USER, 123456789);

    expect(jwt.sign).toHaveBeenCalledTimes(2);
    expect(jwt.sign.mock.calls[0]?.[0]).toHaveProperty('authenticatedAtMs', 123456789);
    expect(jwt.sign.mock.calls[1]?.[0]).toHaveProperty('authenticatedAtMs', 123456789);
  });

  it('omits auth-time from a legacy session rotation when the original token has no claim', async () => {
    const jwt = { sign: jest.fn().mockReturnValue('jwt') };
    const module = await Test.createTestingModule({
      providers: [
        SessionTokenService,
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue('7d') } },
        { provide: RedisService, useValue: { setIfAbsent: jest.fn().mockResolvedValue(true) } },
      ],
    }).compile();

    module.get(SessionTokenService).generate('user-1', UserRole.USER, null);

    for (const [payload] of jwt.sign.mock.calls) {
      expect(payload).not.toHaveProperty('authenticatedAtMs');
    }
  });

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
