import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { NotificationDatabaseRepository } from './data/repositories/notification-database.repository';
import { FcmService } from './fcm.service';
import { PushDeliveryStatus } from './types/push-delivery.types';
import { left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

jest.mock('firebase-admin/app', () => ({
  initializeApp: jest.fn(() => ({})),
  getApps: jest.fn(() => [{}]),
  cert: jest.fn(),
}));

const sendEachForMulticast = jest.fn();
jest.mock('firebase-admin/messaging', () => ({
  getMessaging: jest.fn(() => ({ sendEachForMulticast })),
}));

const FIREBASE_ENV: Record<string, string | undefined> = {
  FIREBASE_PROJECT_ID: 'test-project',
  FIREBASE_PRIVATE_KEY: 'test-key',
  FIREBASE_CLIENT_EMAIL: 'test@test-project.iam.gserviceaccount.com',
};

interface PushTargetOverrides {
  prefs?: Record<string, boolean> | null;
  deletedAt?: Date | null;
  deletionRequestedAt?: Date | null;
  tokens?: string[];
}

function pushTarget(overrides: PushTargetOverrides = {}) {
  return {
    notificationPrefs: overrides.prefs ?? null,
    deletedAt: overrides.deletedAt ?? null,
    deletionRequestedAt: overrides.deletionRequestedAt ?? null,
    pushDevices: (overrides.tokens ?? []).map((token) => ({ token })),
  };
}

function batch(outcomes: Array<{ ok: true } | { ok: false; code: string }>) {
  const responses = outcomes.map((outcome) =>
    outcome.ok ? { error: null } : { error: { code: outcome.code } },
  );
  const failureCount = outcomes.filter((outcome) => !outcome.ok).length;
  return { successCount: outcomes.length - failureCount, failureCount, responses };
}

describe('FcmService delivery result contract', () => {
  let moduleRef: TestingModule;

  async function buildService(firebaseEnv: Record<string, string | undefined>) {
    const repo = {
      findPushTargets: jest.fn(),
      removeInvalidPushTokens: jest.fn().mockResolvedValue(right(undefined)),
    };
    moduleRef = await Test.createTestingModule({
      providers: [
        FcmService,
        {
          provide: ConfigService,
          useValue: { get: (key: string) => firebaseEnv[key] },
        },
        { provide: NotificationDatabaseRepository, useValue: repo },
      ],
    }).compile();
    const service = moduleRef.get(FcmService);
    return { service, repo };
  }

  afterEach(async () => {
    sendEachForMulticast.mockReset();
    await moduleRef.close();
  });

  it('reports fcm_disabled without touching push targets when Firebase credentials are absent', async () => {
    const { service, repo } = await buildService({});

    const result = await service.sendNotification('user-id', 'title', 'body');

    expect(result).toEqual({
      status: PushDeliveryStatus.FcmDisabled,
      deviceCount: 0,
      acceptedCount: 0,
      rejectedCount: 0,
      errors: [],
    });
    expect(repo.findPushTargets).not.toHaveBeenCalled();
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('reports failed with targets_unavailable when push targets cannot be loaded', async () => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(left(new AppError('DATABASE_ERROR', 'failed', 500)));

    const result = await service.sendNotification('user-id', 'title', 'body');

    expect(result.status).toBe(PushDeliveryStatus.Failed);
    expect(result.errors).toEqual(['targets_unavailable']);
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it.each([
    ['the account is deleted', pushTarget({ deletedAt: new Date('2026-01-01'), tokens: ['token-1'] })],
    ['deletion was requested', pushTarget({ deletionRequestedAt: new Date('2026-01-01'), tokens: ['token-1'] })],
    ['the account no longer exists', null],
  ])('reports no_tokens when %s', async (_reason: string, target: ReturnType<typeof pushTarget> | null) => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(right(target));

    const result = await service.sendNotification('user-id', 'title', 'body');

    expect(result.status).toBe(PushDeliveryStatus.NoTokens);
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('reports no_tokens when the account has no registered device', async () => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(right(pushTarget({ tokens: [] })));

    const result = await service.sendNotification('user-id', 'title', 'body');

    expect(result.status).toBe(PushDeliveryStatus.NoTokens);
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('reports opted_out and sends nothing when the matching category preference is off', async () => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(
      right(pushTarget({ prefs: { messages: false }, tokens: ['token-1'] })),
    );

    const result = await service.sendNotification('user-id', 'title', 'body', { type: 'MESSAGE' });

    expect(result.status).toBe(PushDeliveryStatus.OptedOut);
    expect(sendEachForMulticast).not.toHaveBeenCalled();
  });

  it('sends when the matching category preference is explicitly on', async () => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(
      right(pushTarget({ prefs: { messages: true }, tokens: ['token-1'] })),
    );
    sendEachForMulticast.mockResolvedValue(batch([{ ok: true }]));

    const result = await service.sendNotification('user-id', 'title', 'body', { type: 'MESSAGE' });

    expect(result.status).toBe(PushDeliveryStatus.Submitted);
    expect(sendEachForMulticast).toHaveBeenCalledTimes(1);
  });

  it('submits the production payload to every device and reports acceptance counts', async () => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(
      right(pushTarget({ tokens: ['token-1', 'token-2'] })),
    );
    sendEachForMulticast.mockResolvedValue(batch([{ ok: true }, { ok: true }]));

    const result = await service.sendNotification('user-id', 'title', 'body', { type: 'MESSAGE' });

    expect(result).toEqual({
      status: PushDeliveryStatus.Submitted,
      deviceCount: 2,
      acceptedCount: 2,
      rejectedCount: 0,
      errors: [],
    });
    expect(sendEachForMulticast).toHaveBeenCalledWith({
      tokens: ['token-1', 'token-2'],
      notification: { title: 'title', body: 'body' },
      data: { type: 'MESSAGE' },
      android: { priority: 'high', notification: { channelId: 'freebay_notifications' } },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  });

  it('reports rejected devices with the Firebase error code only, keeping tokens out of the result', async () => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(right(pushTarget({ tokens: ['token-1', 'token-2'] })));
    sendEachForMulticast.mockResolvedValue(
      batch([{ ok: true }, { ok: false, code: 'messaging/unknown-error' }]),
    );

    const result = await service.sendNotification('user-id', 'title', 'body');

    expect(result.status).toBe(PushDeliveryStatus.Submitted);
    expect(result.acceptedCount).toBe(1);
    expect(result.rejectedCount).toBe(1);
    expect(result.errors).toEqual(['messaging/unknown-error']);
    expect(repo.removeInvalidPushTokens).not.toHaveBeenCalled();
  });

  it('removes a device whose registration token Firebase reports as not registered', async () => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(right(pushTarget({ tokens: ['token-1', 'token-2'] })));
    sendEachForMulticast.mockResolvedValue(
      batch([{ ok: true }, { ok: false, code: 'messaging/registration-token-not-registered' }]),
    );

    const result = await service.sendNotification('user-id', 'title', 'body');

    expect(result.status).toBe(PushDeliveryStatus.Submitted);
    expect(result.errors).toEqual(['messaging/registration-token-not-registered']);
    expect(repo.removeInvalidPushTokens).toHaveBeenCalledWith('user-id', ['token-2']);
  });

  it('reports failed when every device rejects the message', async () => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(right(pushTarget({ tokens: ['token-1'] })));
    sendEachForMulticast.mockResolvedValue(
      batch([{ ok: false, code: 'messaging/quota-exceeded' }]),
    );

    const result = await service.sendNotification('user-id', 'title', 'body');

    expect(result.status).toBe(PushDeliveryStatus.Failed);
    expect(result.acceptedCount).toBe(0);
    expect(result.errors).toEqual(['messaging/quota-exceeded']);
  });

  it('caps and deduplicates reported error codes across a rejected batch', async () => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(
      right(pushTarget({ tokens: ['a', 'b', 'c', 'd', 'e', 'f', 'g'] })),
    );
    sendEachForMulticast.mockResolvedValue(
      batch([
        { ok: false, code: 'messaging/x-1' },
        { ok: false, code: 'messaging/x-1' },
        { ok: false, code: 'messaging/x-2' },
        { ok: false, code: 'messaging/x-3' },
        { ok: false, code: 'messaging/x-4' },
        { ok: false, code: 'messaging/x-5' },
        { ok: false, code: 'messaging/x-6' },
      ]),
    );

    const result = await service.sendNotification('user-id', 'title', 'body');

    expect(result.errors).toEqual([
      'messaging/x-1',
      'messaging/x-2',
      'messaging/x-3',
      'messaging/x-4',
      'messaging/x-5',
    ]);
  });

  it('reports failed with fcm_send_failed when the Firebase call itself throws', async () => {
    const { service, repo } = await buildService(FIREBASE_ENV);
    repo.findPushTargets.mockResolvedValue(right(pushTarget({ tokens: ['token-1'] })));
    sendEachForMulticast.mockRejectedValue(new Error('FCM unavailable'));

    const result = await service.sendNotification('user-id', 'title', 'body');

    expect(result.status).toBe(PushDeliveryStatus.Failed);
    expect(result.errors).toEqual(['fcm_send_failed']);
  });
});
