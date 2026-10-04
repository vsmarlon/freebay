import { Test } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { JwtTokenType } from '@/shared/core/types';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { SessionTokenService } from '../services/session-token.service';
import { RefreshMobileSessionUseCase } from './refresh-mobile-session.usecase';
import { UserRole } from '@prisma/client';

describe('RefreshMobileSessionUseCase', () => {
  it('atomically claims, revokes, and replaces a mobile refresh session', async () => {
    const users = { findById: jest.fn().mockResolvedValue(right({ id: 'u1', role: UserRole.USER, suspendedAt: null })) };
    const tokens = {
      claimRefresh: jest.fn().mockResolvedValue(true),
      revoke: jest.fn().mockResolvedValue(undefined),
      generate: jest.fn().mockReturnValue({ token: 'access', refreshToken: 'refresh' }),
    };
    const module = await Test.createTestingModule({
      providers: [
        RefreshMobileSessionUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: SessionTokenService, useValue: tokens },
      ],
    }).compile();

    const authenticatedAtMs = Date.now() - 6 * 60 * 1000;
    const payload = {
      userId: 'u1', role: UserRole.USER, type: JwtTokenType.REFRESH, jti: 'j1', exp: 100, authenticatedAtMs,
    };
    const result = await module.get(RefreshMobileSessionUseCase).execute(payload);

    expect(result.isRight()).toBe(true);
    expect(tokens.revoke).toHaveBeenCalledWith('j1', 100);
    expect(tokens.generate).toHaveBeenCalledWith('u1', UserRole.USER, authenticatedAtMs);
  });

  it('does not invent a fresh auth-time for legacy refresh tokens', async () => {
    const users = { findById: jest.fn().mockResolvedValue(right({ id: 'u1', role: UserRole.USER, suspendedAt: null })) };
    const tokens = { claimRefresh: jest.fn().mockResolvedValue(true), revoke: jest.fn(), generate: jest.fn().mockReturnValue({ token: 'access', refreshToken: 'refresh' }) };
    const module = await Test.createTestingModule({
      providers: [RefreshMobileSessionUseCase, { provide: UserDatabaseRepository, useValue: users }, { provide: SessionTokenService, useValue: tokens }],
    }).compile();

    await module.get(RefreshMobileSessionUseCase).execute({
      userId: 'u1', role: UserRole.USER, type: JwtTokenType.REFRESH, jti: 'j1', exp: 9999999999,
    });

    expect(tokens.generate).toHaveBeenCalledWith('u1', UserRole.USER, null);
  });
});
