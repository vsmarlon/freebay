import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import type { Express } from 'express';
import { Pool } from 'pg';
import { AppModule } from '../../src/app.module';
import { ResendService } from '../../src/modules/auth/services/resend.service';
import { AccountDeletionTask } from '../../src/modules/tasks/account-deletion.task';
import { CheckoutExpiryTask } from '../../src/modules/tasks/checkout-expiry.task';
import { DisputeCleanupTask } from '../../src/modules/tasks/dispute-cleanup.task';
import { EscrowReleaseTask } from '../../src/modules/tasks/escrow-release.task';
import { MagicLinkCleanupTask } from '../../src/modules/tasks/magic-link-cleanup.task';
import { StoryCleanupTask } from '../../src/modules/tasks/story-cleanup.task';
import { TransferReconciliationTask } from '../../src/modules/tasks/transfer-reconciliation.task';
import { AllExceptionsFilter } from '../../src/shared/http/exception-filter';
import { TransformInterceptor } from '../../src/shared/http/transform.interceptor';
import { EitherInterceptor } from '../../src/shared/http/response.interceptor';
import { createValidationPipe } from '../../src/shared/http/validation-pipe.factory';
import { assertSafeTestEnvironment, cleanDatabase } from '../utils/test-helpers';

interface ProfileIdentityResponse {
  data?: {
    user?: { id: string };
    token?: string;
    cpf?: string;
  };
  error?: { code?: string };
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL, allowExitOnIdle: true });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

describe('Profile identity verification (HTTP + real database)', () => {
  let app: INestApplication | undefined;
  let baseUrl: string;
  let ownerToken: string;
  let ownerId: string;
  let testClientIp: string;
  let sentCode: string | undefined;
  let sentEmail: string | undefined;
  let failNextEmail = false;
  const suffix = Date.now().toString(36);

  async function call(method: string, path: string, token?: string, body?: object, clientIp = testClientIp) {
    const response = await fetch(`${baseUrl}${path}`, {
      method,
      headers: {
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        'X-Forwarded-For': clientIp,
        ...(body ? { 'Content-Type': 'application/json' } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    return {
      status: response.status,
      json: (await response.json()) as ProfileIdentityResponse,
    };
  }

  beforeAll(async () => {
    assertSafeTestEnvironment();
    if (process.env.STRIPE_SECRET_KEY === 'e2e_fake_stripe_key_not_real') {
      process.env.STRIPE_SECRET_KEY = 'sk_test_profile_identity_e2e_not_real';
    }
    await prisma.$connect();
    const targets = await prisma.$queryRaw<
      Array<{ database: string; schema: string }>
    >`SELECT current_database() AS database, current_schema() AS schema`;
    if (
      targets.length !== 1 ||
      targets[0].database !== 'freebay_test_db' ||
      targets[0].schema !== 'public'
    ) {
      throw new Error('Refusing profile identity E2E outside freebay_test_db/public');
    }

    await cleanDatabase(prisma);
    const builder = Test.createTestingModule({ imports: [AppModule] });
    builder.overrideProvider(ResendService).useValue({ sendProfileVerificationCode: async (email: string, code: string, _locale: 'pt-BR' | 'en'): Promise<boolean> => { sentEmail = email; sentCode = code; if (failNextEmail) { failNextEmail = false; return false; } return true; } });
    for (const task of [AccountDeletionTask, CheckoutExpiryTask, DisputeCleanupTask, EscrowReleaseTask, MagicLinkCleanupTask, StoryCleanupTask, TransferReconciliationTask]) {
      builder.overrideProvider(task).useValue({});
    }
    const module = await builder.compile();
    const application = module.createNestApplication();
    app = application;
    const expressApp: Express = application.getHttpAdapter().getInstance();
    expressApp.set('trust proxy', 'loopback');
    application.useGlobalPipes(createValidationPipe());
    application.useGlobalFilters(new AllExceptionsFilter());
    application.useGlobalInterceptors(new TransformInterceptor(), new EitherInterceptor());
    await application.init();
    await application.listen(0, '127.0.0.1');
    const address = application.getHttpServer().address();
    if (!address || typeof address === 'string') throw new Error('No HTTP port');
    baseUrl = `http://127.0.0.1:${address.port}`;
    testClientIp = '198.51.100.21';

    const registration = await call('POST', '/auth/register', undefined, {
      displayName: 'Profile Identity Owner',
      username: `pi_${suffix}`,
      email: `profile-identity-${suffix}@example.com`,
      password: 'password123',
    });
    if (registration.status !== 201 || !registration.json.data?.token) {
      throw new Error(`Profile identity owner fixture failed with HTTP ${registration.status}`);
    }
    ownerToken = registration.json.data.token;
    ownerId = registration.json.data.user?.id ?? '';
  }, 120000);

  afterAll(async () => {
    await app?.close();
    await cleanDatabase(prisma);
    await prisma.$disconnect();
    await pool.end();
  });

  it('requires fresh verification before changing the account CPF', async () => {
    const response = await call(
      'PATCH',
      '/users/me',
      ownerToken,
      { cpf: '529.982.247-25' },
    );

    expect(response.status).toBe(403);
    expect(response.json.error?.code).toBe('PROFILE_VERIFICATION_REQUIRED');
  });

  it('uses a code sent to the current email to authorize normalized CPF storage', async () => {
    const secondaryEmail = `pi-secondary-${suffix}@example.com`;
    const secondaryRegistration = await call('POST', '/auth/register', undefined, {
      displayName: 'Profile Identity Secondary',
      username: `pis_${suffix}`,
      email: secondaryEmail,
      password: 'password123',
    });
    const secondaryToken = secondaryRegistration.json.data?.token;
    expect(secondaryRegistration.status).toBe(201);
    expect(secondaryToken).toBeDefined();

    const secondaryRequest = await call('POST', '/users/me/profile-verification', secondaryToken, { cpf: '529.982.247-25' }, '198.51.100.31');
    expect(secondaryRequest.status).toBe(200);
    const secondaryCode = sentCode;
    const crossUser = await call('PATCH', '/users/me', ownerToken, { cpf: '529.982.247-25', profileVerificationCode: secondaryCode }, '198.51.100.32');
    expect(crossUser.status).toBe(410);
    expect((await prisma.user.findUniqueOrThrow({ where: { id: ownerId }, select: { cpf: true } })).cpf).toBeNull();
    const wrongCode = secondaryCode === '000000' ? '000001' : '000000';
    const wrongAttempts = await Promise.all(Array.from({ length: 5 }, (_, index) =>
      call('PATCH', '/users/me', secondaryToken, { cpf: '529.982.247-25', profileVerificationCode: wrongCode }, `198.51.100.${40 + index}`),
    ));
    expect(wrongAttempts.map((response) => response.status).sort((a, b) => a - b)).toEqual([400, 400, 400, 400, 429]);
    const lockedReplay = await call('PATCH', '/users/me', secondaryToken, { cpf: '529.982.247-25', profileVerificationCode: secondaryCode }, '198.51.100.50');
    expect(lockedReplay.status).toBe(410);
    const cooldown = await call('POST', '/users/me/profile-verification', secondaryToken, { cpf: '529.982.247-25' }, '198.51.100.51');
    expect(cooldown.status).toBe(429);

    const failedEmail = await call('POST', '/auth/register', undefined, {
      displayName: 'Profile Identity Failed Delivery',
      username: `pif_${suffix}`,
      email: `pi-failed-${suffix}@example.com`,
      password: 'password123',
    });
    const failedDeliveryToken = failedEmail.json.data?.token;
    expect(failedDeliveryToken).toBeDefined();
    failNextEmail = true;
    expect((await call('POST', '/users/me/profile-verification', failedDeliveryToken, { cpf: '529.982.247-25' }, '198.51.100.52')).status).toBe(503);
    expect((await call('PATCH', '/users/me', failedDeliveryToken, { cpf: '529.982.247-25' }, '198.51.100.53')).status).toBe(403);

    const request = await call('POST', '/users/me/profile-verification', ownerToken, { cpf: '529.982.247-25', locale: 'pt-BR' }, '198.51.100.54');
    expect(request.status).toBe(200);
    expect(request.json).not.toHaveProperty('data.code');
    expect(sentCode).toMatch(/^\d{6}$/);
    expect(sentEmail).toBe(`profile-identity-${suffix}@example.com`);
    const malformed = await call('PATCH', '/users/me', ownerToken, { cpf: null, profileVerificationCode: sentCode }, '198.51.100.55');
    expect(malformed.status).toBe(400);
    const originalEmail = sentEmail;
    await prisma.user.update({ where: { id: ownerId }, data: { email: 'changed-profile-identity@example.com' } });
    const changedEmail = await call('PATCH', '/users/me', ownerToken, { cpf: '529.982.247-25', profileVerificationCode: sentCode }, '198.51.100.56');
    expect(changedEmail.status).toBe(400);
    await prisma.user.update({ where: { id: ownerId }, data: { email: originalEmail } });
    const concurrentUpdates = await Promise.all([
      call('PATCH', '/users/me', ownerToken, { cpf: '529.982.247-25', profileVerificationCode: sentCode }, '198.51.100.57'),
      call('PATCH', '/users/me', ownerToken, { cpf: '529.982.247-25', profileVerificationCode: sentCode }, '198.51.100.58'),
    ]);
    expect(concurrentUpdates.map((response) => response.status).sort()).toEqual([200, 410]);
    expect(concurrentUpdates.find((response) => response.status === 200)?.json.data?.cpf).toBe('529.***.***-25');
    const stored = await prisma.user.findUniqueOrThrow({ where: { id: ownerId }, select: { cpf: true, emailVerified: true, isVerified: true } });
    expect(stored.cpf).toBe('52998224725');
    expect(stored.emailVerified).toBe(false);
    expect(stored.isVerified).toBe(false);
    const replay = await call('PATCH', '/users/me', ownerToken, { cpf: '52998224725', profileVerificationCode: sentCode });
    expect(replay.status).toBe(410);
    expect(replay.json.error?.code).toBe('PROFILE_VERIFICATION_EXPIRED');
  });
});
