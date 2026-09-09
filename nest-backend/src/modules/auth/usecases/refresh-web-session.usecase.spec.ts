import { Test } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { JwtTokenType } from '@/shared/core/types';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { SessionTokenService } from '../services/session-token.service';
import { RefreshWebSessionUseCase } from './refresh-web-session.usecase';

describe('RefreshWebSessionUseCase', () => {
  it('allows exactly one concurrent rotation for a refresh jti', async () => {
    const users = { findById: jest.fn().mockResolvedValue(right({ id: 'u1', role: 'USER', suspendedAt: null })) };
    let claimed = false;
    const tokens = {
      claimRefresh: jest.fn().mockImplementation(async () => {
        if (claimed) return false;
        claimed = true;
        return true;
      }),
      generate: jest.fn().mockReturnValue({ token: 'access', refreshToken: 'refresh' }),
    };
    const module = await Test.createTestingModule({
      providers: [RefreshWebSessionUseCase, { provide: UserDatabaseRepository, useValue: users }, { provide: SessionTokenService, useValue: tokens }],
    }).compile();
    const payload = { userId: 'u1', role: 'USER', type: JwtTokenType.REFRESH, jti: 'j1', exp: Math.floor(Date.now() / 1000) + 60 };
    const results = await Promise.all([module.get(RefreshWebSessionUseCase).execute(payload), module.get(RefreshWebSessionUseCase).execute(payload)]);
    expect(results.filter((result) => result.isRight())).toHaveLength(1);
    expect(tokens.claimRefresh).toHaveBeenCalledTimes(2);
  });

  it('rejects suspended users before claiming the refresh token', async () => {
    const users = { findById: jest.fn().mockResolvedValue(right({ id: 'u1', role: 'USER', suspendedAt: new Date(), suspensionReason: 'fraud' })) };
    const tokens = { claimRefresh: jest.fn(), generate: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [RefreshWebSessionUseCase, { provide: UserDatabaseRepository, useValue: users }, { provide: SessionTokenService, useValue: tokens }],
    }).compile();
    const result = await module.get(RefreshWebSessionUseCase).execute({ userId: 'u1', role: 'USER', type: JwtTokenType.REFRESH, jti: 'j1', exp: 9999999999 });
    expect(result.isLeft()).toBe(true);
    expect(tokens.claimRefresh).not.toHaveBeenCalled();
  });
});
