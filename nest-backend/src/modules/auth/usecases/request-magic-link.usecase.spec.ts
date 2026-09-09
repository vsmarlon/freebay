import { Test } from '@nestjs/testing';
import { left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { ResendService } from '../services/resend.service';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { RequestMagicLinkUseCase } from './request-magic-link.usecase';

describe('RequestMagicLinkUseCase', () => {
  it('normalizes email, stores only a hash, and expires after ten minutes', async () => {
    const repository = { create: jest.fn().mockResolvedValue(right({ id: 'credential-id' })), recordSendAccepted: jest.fn().mockResolvedValue(right({})) };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValue(1) };
    const resend = { sendMagicLink: jest.fn().mockResolvedValue({ id: 'message-id' }) };
    const module = await Test.createTestingModule({
      providers: [
        RequestMagicLinkUseCase,
        { provide: MagicLinkRepository, useValue: repository },
        { provide: RedisService, useValue: redis },
        { provide: ResendService, useValue: resend },
      ],
    }).compile();
    const usecase = module.get(RequestMagicLinkUseCase);

    const before = Date.now();
    const result = await usecase.execute({
      email: '  USER@Example.COM ',
      consent: true,
      locale: 'en',
      ip: '127.0.0.1',
    });
    const data = repository.create.mock.calls[0][0];

    expect(result.isRight()).toBe(true);
    expect(data.email).toBe('user@example.com');
    expect(data.tokenHash).not.toContain('USER');
    expect(data.tokenHash).toHaveLength(64);
    expect(data.activatedAt).toBe(data.requestedAt);
    expect(data.expiresAt.getTime() - data.requestedAt.getTime()).toBe(600000);
    expect(data.requestedAt.getTime()).toBeGreaterThanOrEqual(before);
    expect(resend.sendMagicLink).toHaveBeenCalledWith('user@example.com', expect.any(String), 'en', 'credential-id');
    expect(repository.create.mock.invocationCallOrder[0]).toBeLessThan(resend.sendMagicLink.mock.invocationCallOrder[0]);
    expect(JSON.stringify(data)).not.toContain(resend.sendMagicLink.mock.calls[0][1]);
    expect(repository.recordSendAccepted).toHaveBeenCalledWith('credential-id', expect.any(Date), 'message-id');
    expect(redis.incrementWithExpiry).toHaveBeenCalledTimes(2);
  });

  it('returns generic success when either throttle bucket is exceeded', async () => {
    const repository = { create: jest.fn(), recordSendAccepted: jest.fn() };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValueOnce(6).mockResolvedValueOnce(1) };
    const resend = { sendMagicLink: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        RequestMagicLinkUseCase,
        { provide: MagicLinkRepository, useValue: repository },
        { provide: RedisService, useValue: redis },
        { provide: ResendService, useValue: resend },
      ],
    }).compile();

    const result = await module.get(RequestMagicLinkUseCase).execute({
      email: 'user@example.com', consent: true, locale: 'pt-BR', ip: '127.0.0.1',
    });

    expect(result.isRight()).toBe(true);
    expect(repository.create).not.toHaveBeenCalled();
    expect(resend.sendMagicLink).not.toHaveBeenCalled();
  });

  it('removes the pending credential and returns a generic delivery error when the provider fails', async () => {
    const repository = { create: jest.fn().mockResolvedValue(right({ id: 'credential-id' })), recordSendAccepted: jest.fn() };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValue(1) };
    const resend = { sendMagicLink: jest.fn().mockRejectedValue(new Error('provider detail')) };
    const module = await Test.createTestingModule({
      providers: [RequestMagicLinkUseCase, { provide: MagicLinkRepository, useValue: repository }, { provide: RedisService, useValue: redis }, { provide: ResendService, useValue: resend }],
    }).compile();
    const result = await module.get(RequestMagicLinkUseCase).execute({ email: 'user@example.com', consent: true, locale: 'en', ip: '127.0.0.1' });
    expect(result).toEqual(right({ sent: true }));
    expect(JSON.stringify(result)).not.toContain('provider detail');
    expect(repository.recordSendAccepted).not.toHaveBeenCalled();
  });

  it('keeps the credential inactive when delivery finalization fails', async () => {
    const repository = {
      create: jest.fn().mockResolvedValue(right({})),
      recordSendAccepted: jest.fn().mockResolvedValue(left(new DatabaseError('database unavailable'))),
    };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValue(1) };
    const resend = { sendMagicLink: jest.fn().mockResolvedValue({ id: 'message-id' }) };
    const module = await Test.createTestingModule({
      providers: [RequestMagicLinkUseCase, { provide: MagicLinkRepository, useValue: repository }, { provide: RedisService, useValue: redis }, { provide: ResendService, useValue: resend }],
    }).compile();

    const result = await module.get(RequestMagicLinkUseCase).execute({ email: 'user@example.com', consent: true, locale: 'en', ip: '127.0.0.1' });

    expect(result).toEqual(right({ sent: true }));
    expect(repository.recordSendAccepted).toHaveBeenCalled();
  });
});
