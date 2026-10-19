import { Test } from '@nestjs/testing';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { ConfigService } from '@nestjs/config';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';
import { SESSION_FAMILY_REVOKED_PREFIX, SESSION_INVALID_BEFORE_PREFIX, SessionRevokerService } from './session-revoker.service';

describe('SessionRevokerService', () => {
  it('stores an invalid-before timestamp with millisecond precision', async () => {
    const redis = { add: jest.fn().mockResolvedValue(undefined), del: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [SessionRevokerService, { provide: RedisService, useValue: redis }, { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue('7d') } }, { provide: AuthSessionStateDatabaseRepository, useValue: { advanceInvalidBefore: jest.fn() } }],
    }).compile();
    const before = Date.now();

    await module.get(SessionRevokerService).revokeAllSessions('user-1');

    const storedTimestamp = Number(redis.add.mock.calls[0][1]);
    expect(redis.add).toHaveBeenCalledWith(expect.stringContaining(SESSION_INVALID_BEFORE_PREFIX), expect.any(String), 2592000);
    expect(storedTimestamp).toBeGreaterThanOrEqual(before);
  });

  it('revokes a family for the maximum configured access, refresh, and biometric lifetime', async () => {
    const redis = { add: jest.fn().mockResolvedValue(undefined) };
    const config = { get: jest.fn((key: string) => key === 'JWT_BIOMETRIC_EXPIRES_IN' ? '90d' : key === 'JWT_EXPIRES_IN' ? '60d' : '7d') };
    const module = await Test.createTestingModule({
      providers: [SessionRevokerService, { provide: RedisService, useValue: redis }, { provide: ConfigService, useValue: config }, { provide: AuthSessionStateDatabaseRepository, useValue: { advanceInvalidBefore: jest.fn() } }],
    }).compile();

    await module.get(SessionRevokerService).revokeFamily('family-1');

    expect(redis.add).toHaveBeenCalledWith(`${SESSION_FAMILY_REVOKED_PREFIX}family-1`, '1', 90 * 24 * 60 * 60);
  });
});
