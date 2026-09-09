import { Test } from '@nestjs/testing';
import { left, right } from '@/shared/core/either';
import { InvalidTokenError } from '@/shared/core/errors';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { ConsumeMagicLinkUseCase } from './consume-magic-link.usecase';

describe('ConsumeMagicLinkUseCase', () => {
  it('rejects an expired, consumed, or unknown token without exposing its state', async () => {
    const repository = { consume: jest.fn().mockResolvedValue(right(null)) };
    const module = await Test.createTestingModule({
      providers: [
        ConsumeMagicLinkUseCase,
        { provide: MagicLinkRepository, useValue: repository },
      ],
    }).compile();

    const result = await module.get(ConsumeMagicLinkUseCase).execute({ token: 'a'.repeat(32) });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(InvalidTokenError);
    expect(repository.consume).toHaveBeenCalledWith(expect.any(String), expect.any(Date));
  });

  it('propagates repository failures as Either failures', async () => {
    const failure = new InvalidTokenError();
    const repository = { consume: jest.fn().mockResolvedValue(left(failure)) };
    const module = await Test.createTestingModule({
      providers: [
        ConsumeMagicLinkUseCase,
        { provide: MagicLinkRepository, useValue: repository },
      ],
    }).compile();

    const result = await module.get(ConsumeMagicLinkUseCase).execute({ token: 'b'.repeat(32) });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBe(failure);
  });
});
