import { Test } from '@nestjs/testing';
import { left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { ResendService } from '../services/resend.service';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { RequestMagicLinkUseCase } from './request-magic-link.usecase';

describe('RequestMagicLinkUseCase', () => {
  type Mocks = {
    repository: { create: jest.Mock; recordSendAccepted: jest.Mock };
    redis: { incrementWithExpiry: jest.Mock };
    resend: { sendMagicLink: jest.Mock };
  };

  const compileSubject = async (mocks: Mocks): Promise<RequestMagicLinkUseCase> => {
    const module = await Test.createTestingModule({
      providers: [
        RequestMagicLinkUseCase,
        { provide: MagicLinkRepository, useValue: mocks.repository },
        { provide: RedisService, useValue: mocks.redis },
        { provide: ResendService, useValue: mocks.resend },
      ],
    }).compile();
    return module.get(RequestMagicLinkUseCase);
  };

  it('normalizes email, stores only a hash, and expires after ten minutes', async () => {
    const mocks: Mocks = {
      repository: {
        create: jest.fn().mockResolvedValue(right({ id: 'credential-id' })),
        recordSendAccepted: jest.fn().mockResolvedValue(right({})),
      },
      redis: { incrementWithExpiry: jest.fn().mockResolvedValue(1) },
      resend: { sendMagicLink: jest.fn().mockResolvedValue({ id: 'message-id' }) },
    };
    const usecase = await compileSubject(mocks);

    const before = Date.now();
    const result = await usecase.execute({
      email: '  USER@Example.COM ', consent: true, locale: 'en', ip: '127.0.0.1',
    });
    const data = mocks.repository.create.mock.calls[0][0];

    expect(result.isRight()).toBe(true);
    expect(data.email).toBe('user@example.com');
    expect(data.tokenHash).not.toContain('USER');
    expect(data.tokenHash).toHaveLength(64);
    expect(data.activatedAt).toBe(data.requestedAt);
    expect(data.expiresAt.getTime() - data.requestedAt.getTime()).toBe(600000);
    expect(data.requestedAt.getTime()).toBeGreaterThanOrEqual(before);
    expect(mocks.resend.sendMagicLink).toHaveBeenCalledWith(
      'user@example.com', expect.any(String), 'en', 'credential-id',
    );
    expect(mocks.repository.create.mock.invocationCallOrder[0]).toBeLessThan(
      mocks.resend.sendMagicLink.mock.invocationCallOrder[0],
    );
    expect(JSON.stringify(data)).not.toContain(mocks.resend.sendMagicLink.mock.calls[0][1]);
    expect(mocks.repository.recordSendAccepted).toHaveBeenCalledWith(
      'credential-id', expect.any(Date), 'message-id',
    );
    expect(mocks.redis.incrementWithExpiry).toHaveBeenCalledTimes(2);
  });

  it('returns generic success when either throttle bucket is exceeded', async () => {
    const mocks: Mocks = {
      repository: { create: jest.fn(), recordSendAccepted: jest.fn() },
      redis: { incrementWithExpiry: jest.fn().mockResolvedValueOnce(6).mockResolvedValueOnce(1) },
      resend: { sendMagicLink: jest.fn() },
    };

    const result = await (await compileSubject(mocks)).execute({
      email: 'user@example.com', consent: true, locale: 'pt-BR', ip: '127.0.0.1',
    });

    expect(result.isRight()).toBe(true);
    expect(mocks.repository.create).not.toHaveBeenCalled();
    expect(mocks.resend.sendMagicLink).not.toHaveBeenCalled();
  });

  it('removes the pending credential and returns a generic delivery error when the provider fails', async () => {
    const mocks: Mocks = {
      repository: {
        create: jest.fn().mockResolvedValue(right({ id: 'credential-id' })),
        recordSendAccepted: jest.fn(),
      },
      redis: { incrementWithExpiry: jest.fn().mockResolvedValue(1) },
      resend: { sendMagicLink: jest.fn().mockRejectedValue(new Error('provider detail')) },
    };
    const result = await (await compileSubject(mocks)).execute({
      email: 'user@example.com', consent: true, locale: 'en', ip: '127.0.0.1',
    });

    expect(result).toEqual(right({ sent: true }));
    expect(JSON.stringify(result)).not.toContain('provider detail');
    expect(mocks.repository.recordSendAccepted).not.toHaveBeenCalled();
  });

  it('keeps the credential inactive when delivery finalization fails', async () => {
    const mocks: Mocks = {
      repository: {
        create: jest.fn().mockResolvedValue(right({})),
        recordSendAccepted: jest.fn().mockResolvedValue(left(new DatabaseError('database unavailable'))),
      },
      redis: { incrementWithExpiry: jest.fn().mockResolvedValue(1) },
      resend: { sendMagicLink: jest.fn().mockResolvedValue({ id: 'message-id' }) },
    };

    const result = await (await compileSubject(mocks)).execute({
      email: 'user@example.com', consent: true, locale: 'en', ip: '127.0.0.1',
    });

    expect(result).toEqual(right({ sent: true }));
    expect(mocks.repository.recordSendAccepted).toHaveBeenCalled();
  });
});
