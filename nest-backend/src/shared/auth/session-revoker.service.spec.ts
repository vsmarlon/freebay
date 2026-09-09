import { Test } from '@nestjs/testing';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { SESSION_INVALID_BEFORE_PREFIX, SessionRevokerService } from './session-revoker.service';

describe('SessionRevokerService', () => {
  it('stores an invalid-before timestamp with millisecond precision', async () => {
    const redis = { add: jest.fn().mockResolvedValue(undefined), del: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [SessionRevokerService, { provide: RedisService, useValue: redis }],
    }).compile();
    const before = Date.now();

    await module.get(SessionRevokerService).revokeAllSessions('user-1');

    const storedTimestamp = Number(redis.add.mock.calls[0][1]);
    expect(redis.add).toHaveBeenCalledWith(expect.stringContaining(SESSION_INVALID_BEFORE_PREFIX), expect.any(String), 2592000);
    expect(storedTimestamp).toBeGreaterThanOrEqual(before);
  });
});
