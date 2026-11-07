import { StepUpPurpose } from '@/shared/auth/biometric-credential.service';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { right } from '@/shared/core/either';
import { RedisService } from '@/shared/infra/redis/redis.service';
import { UserDatabaseRepository } from '@/modules/users';
import { MagicLinkRepository } from '../domain/repositories/magic-link.repository';
import { ResendService } from '../services/resend.service';
import { RequestWebStepUpMagicLinkUseCase } from './request-web-step-up-magic-link.usecase';
import { verifyStepUpMagicContext } from '../utils/step-up-magic-context';

describe('RequestWebStepUpMagicLinkUseCase', () => {
  const activeUser = {
    id: 'user-1', email: 'Owner@Example.com', suspendedAt: null, deletedAt: null, sessionsInvalidBefore: null,
  };

  it('emails only the current active user and creates a consent-neutral, single-use step-up credential', async () => {
    const users = { findById: jest.fn().mockResolvedValue(right(activeUser)) };
    const repository = {
      create: jest.fn().mockImplementation(async (data: Record<string, unknown>) => right({ id: 'magic-link-1', ...data })),
      recordSendAccepted: jest.fn().mockResolvedValue(right({})),
    };
    const redis = { incrementWithExpiry: jest.fn().mockResolvedValue(1) };
    const resend = { sendStepUpMagicLink: jest.fn().mockResolvedValue({ id: 'resend-1' }) };
    const secret = 'step-up-email-test-secret';
    const module = await Test.createTestingModule({
      providers: [
        RequestWebStepUpMagicLinkUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: MagicLinkRepository, useValue: repository },
        { provide: RedisService, useValue: redis },
        { provide: ResendService, useValue: resend },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn(() => secret) } },
      ],
    }).compile();

    const result = await module.get(RequestWebStepUpMagicLinkUseCase).execute({
      user: { userId: activeUser.id, role: UserRole.USER, sessionStartedAtMs: 1_700_000_000_000 },
      body: { purpose: StepUpPurpose.CANCEL_ORDER, resourceId: '550e8400-e29b-41d4-a716-446655440000', locale: 'en', consent: true },
      ip: '192.0.2.10', userAgent: 'test-agent',
    });

    expect(result.isRight()).toBe(true);
    expect(users.findById).toHaveBeenCalledWith(activeUser.id);
    const created = repository.create.mock.calls[0][0];
    expect(created).toMatchObject({ email: 'owner@example.com', consentGranted: false, consentAt: null, activatedAt: expect.any(Date) });
    expect(created.tokenHash).toMatch(/^[a-f0-9]{64}$/);
    const [email, token, signature, purpose, resourceId, locale] = resend.sendStepUpMagicLink.mock.calls[0];
    expect(email).toBe('owner@example.com');
    expect(token).toMatch(/^stepup\.[A-Za-z0-9_-]{43}$/);
    expect(verifyStepUpMagicContext(secret, {
      userId: activeUser.id, purpose, resourceId, tokenHash: created.tokenHash,
    }, signature)).toBe(true);
    expect([purpose, resourceId, locale]).toEqual([StepUpPurpose.CANCEL_ORDER, '550e8400-e29b-41d4-a716-446655440000', 'en']);
    expect(redis.incrementWithExpiry).toHaveBeenCalledTimes(2);
  });

  it('does not look up a user or issue a link for malformed action resources', async () => {
    const users = { findById: jest.fn() };
    const repository = { create: jest.fn() };
    const module = await Test.createTestingModule({
      providers: [
        RequestWebStepUpMagicLinkUseCase,
        { provide: UserDatabaseRepository, useValue: users },
        { provide: MagicLinkRepository, useValue: repository },
        { provide: RedisService, useValue: { incrementWithExpiry: jest.fn() } },
        { provide: ResendService, useValue: { sendStepUpMagicLink: jest.fn() } },
        { provide: ConfigService, useValue: { getOrThrow: jest.fn() } },
      ],
    }).compile();

    const result = await module.get(RequestWebStepUpMagicLinkUseCase).execute({
      user: { userId: 'user-1', role: UserRole.USER, sessionStartedAtMs: 1_700_000_000_000 },
      body: { purpose: StepUpPurpose.CANCEL_ORDER, resourceId: 'not-a-uuid', locale: 'en', consent: true },
      ip: '192.0.2.10',
    });

    expect(result.isRight()).toBe(true);
    expect(users.findById).not.toHaveBeenCalled();
    expect(repository.create).not.toHaveBeenCalled();
  });
});
