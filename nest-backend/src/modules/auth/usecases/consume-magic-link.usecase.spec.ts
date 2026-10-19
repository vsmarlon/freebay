import { Test } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { InvalidTokenError } from '@/shared/core/errors';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { ConsumeMagicLinkUseCase } from './consume-magic-link.usecase';
import { SessionTokenService } from '../services/session-token.service';
import { UserRole } from '@prisma/client';

describe('ConsumeMagicLinkUseCase', () => {
  it('uses the original magic-link request time as the signed session origin', async () => {
    const requestedAt = new Date(1_234_567_890);
    const repository = { consume: jest.fn().mockResolvedValue(right({
      user: { id: 'u1', role: UserRole.USER, suspendedAt: null, suspensionReason: null },
      sessionStartedAtMs: requestedAt.getTime(),
    })) };
    const tokens = { generate: jest.fn().mockReturnValue({ token: 'access', refreshToken: 'refresh' }) };
    const module = await Test.createTestingModule({
      providers: [
        ConsumeMagicLinkUseCase,
        { provide: MagicLinkRepository, useValue: repository },
        { provide: SessionTokenService, useValue: tokens },
      ],
    }).compile();

    await module.get(ConsumeMagicLinkUseCase).execute({ token: 'a'.repeat(32) });

    expect(tokens.generate).toHaveBeenCalledWith('u1', UserRole.USER, expect.any(Number), undefined, requestedAt.getTime());
  });

  it('does not provision a new account from an account-deletion email link', async () => {
    const repository = { consume: jest.fn().mockResolvedValue(right(null)) };
    const module = await Test.createTestingModule({
      providers: [
        ConsumeMagicLinkUseCase,
        { provide: MagicLinkRepository, useValue: repository },
        { provide: SessionTokenService, useValue: { generate: jest.fn().mockReturnValue({ token: 'access', refreshToken: 'refresh' }) } },
      ],
    }).compile();

    await module.get(ConsumeMagicLinkUseCase).execute({ token: `delete.${'a'.repeat(32)}` });

    expect(repository.consume).toHaveBeenCalledWith(expect.any(String), expect.any(Date), false);
  });

  it('rejects an expired, consumed, or unknown token without exposing its state', async () => {
    const repository = { consume: jest.fn().mockResolvedValue(right(null)) };
    const module = await Test.createTestingModule({
      providers: [
        ConsumeMagicLinkUseCase,
        { provide: MagicLinkRepository, useValue: repository },
        { provide: SessionTokenService, useValue: { generate: jest.fn().mockReturnValue({ token: 'access', refreshToken: 'refresh' }) } },
      ],
    }).compile();

    const result = await module.get(ConsumeMagicLinkUseCase).execute({ token: 'a'.repeat(32) });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(InvalidTokenError);
    expect(repository.consume).toHaveBeenCalledWith(expect.any(String), expect.any(Date), true);
  });

  it('never sends a step-up-only credential through the login/account-creation consumer', async () => {
    const repository = { consume: jest.fn().mockResolvedValue(right(null)) };
    const module = await Test.createTestingModule({
      providers: [
        ConsumeMagicLinkUseCase,
        { provide: MagicLinkRepository, useValue: repository },
        { provide: SessionTokenService, useValue: { generate: jest.fn() } },
      ],
    }).compile();

    const result = await module.get(ConsumeMagicLinkUseCase).execute({ token: `stepup.${'a'.repeat(43)}` });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(InvalidTokenError);
    expect(repository.consume).not.toHaveBeenCalled();
  });

});
