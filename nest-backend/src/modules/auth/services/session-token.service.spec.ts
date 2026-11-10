import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { SessionTokenService } from './session-token.service';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { UserRole } from '@prisma/client';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';

describe('SessionTokenService', () => {
  it('preserves the authentication timestamp in both signed session tokens', async () => {
    const jwt = { sign: jest.fn().mockReturnValue('jwt') };
    const module = await Test.createTestingModule({
      providers: [
        SessionTokenService,
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue('7d') } },
        { provide: RedisService, useValue: { setIfAbsent: jest.fn().mockResolvedValue(true) } },
        { provide: SessionRevokerService, useValue: { revokeFamily: jest.fn() } },
      ],
    }).compile();

    const before = Date.now();
    module.get(SessionTokenService).generate('user-1', UserRole.USER, 123456789, undefined, 123456789);

    expect(jwt.sign).toHaveBeenCalledTimes(2);
    expect(jwt.sign.mock.calls[0]?.[0]).toHaveProperty('authenticatedAtMs', 123456789);
    expect(jwt.sign.mock.calls[1]?.[0]).toHaveProperty('authenticatedAtMs', 123456789);
    expect(jwt.sign.mock.calls[0]?.[0]).toHaveProperty('sessionStartedAtMs', 123456789);
    expect(jwt.sign.mock.calls[1]?.[0]).toHaveProperty('sessionStartedAtMs', 123456789);
    expect(jwt.sign.mock.calls[0]?.[0].issuedAtMs).toBeGreaterThanOrEqual(before);
    expect(jwt.sign.mock.calls[0]?.[0].issuedAtMs).not.toBe(123456789);
    expect(jwt.sign.mock.calls[0]?.[0].sid).toBe(jwt.sign.mock.calls[1]?.[0].sid);
    expect(jwt.sign.mock.calls[0]?.[0].sid).toEqual(expect.any(String));
  });

  it('omits auth-time from a legacy session rotation when the original token has no claim', async () => {
    const jwt = { sign: jest.fn().mockReturnValue('jwt') };
    const module = await Test.createTestingModule({
      providers: [
        SessionTokenService,
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue('7d') } },
        { provide: RedisService, useValue: { setIfAbsent: jest.fn().mockResolvedValue(true) } },
        { provide: SessionRevokerService, useValue: { revokeFamily: jest.fn() } },
      ],
    }).compile();

    module.get(SessionTokenService).generate('user-1', UserRole.USER, null, undefined, 123456789);

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
        { provide: SessionRevokerService, useValue: { revokeFamily: jest.fn() } },
      ],
    }).compile();

    const service = module.get(SessionTokenService);

    expect(service.generate('user-1', UserRole.USER, Date.now(), undefined, 123456789)).toEqual({
      token: 'jwt',
      refreshToken: 'jwt',
    });
    expect(service.generateBiometric('user-1', UserRole.USER, undefined, 123456789)).toBe('jwt');
  });

  it('revokes the whole session family when a rotated refresh token is reused', async () => {
    const jwt = { sign: jest.fn().mockReturnValue('jwt') };
    const redis = {
      setIfAbsent: jest.fn().mockResolvedValue(false),
      add: jest.fn().mockResolvedValue(undefined),
    };
    const module = await Test.createTestingModule({
      providers: [
        SessionTokenService,
        { provide: JwtService, useValue: jwt },
        { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue('7d') } },
        { provide: RedisService, useValue: redis },
        SessionRevokerService,
        { provide: AuthSessionStateDatabaseRepository, useValue: { advanceInvalidBefore: jest.fn() } },
      ],
    }).compile();

    const claimed = await module.get(SessionTokenService).claimRefresh('refresh-jti', Math.floor(Date.now() / 1000) + 60, 'family-1');

    expect(claimed).toBe(false);
    expect(redis.add).toHaveBeenCalledWith('session_family_revoked:family-1', '1', expect.any(Number));
  });
});
