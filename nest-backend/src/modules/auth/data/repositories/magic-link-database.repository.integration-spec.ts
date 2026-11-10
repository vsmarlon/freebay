import { Test, TestingModule } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { createHash, randomBytes } from 'crypto';
import { prisma } from '../../../../../test/setup-integration';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { MagicLinkDatabaseRepository } from './magic-link-database.repository';

describe('MagicLinkDatabaseRepository integration', () => {
  let repository: MagicLinkDatabaseRepository;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MagicLinkDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    repository = module.get(MagicLinkDatabaseRepository);
  });

  it('allows exactly one concurrent consumption and initializes one user and wallet', async () => {
    const rawToken = randomBytes(32).toString('base64url');
    const email = `magic-${Date.now()}@example.com`;
    const input: Prisma.WebMagicLinkCreateInput = {
      email,
      tokenHash: createHash('sha256').update(rawToken).digest('hex'),
      consentGranted: true,
      consentAt: new Date(),
      activatedAt: new Date(),
      expiresAt: new Date(Date.now() + 600000),
    };
    await repository.create(input);

    const results = await Promise.all([
      repository.consume(input.tokenHash, new Date()),
      repository.consume(input.tokenHash, new Date()),
    ]);
    const successful = results.filter((result) => result.isRight() && result.value !== null);
    const loser = results.filter((result) => result.isRight() && result.value === null);

    expect(successful).toHaveLength(1);
    expect(loser).toHaveLength(1);
    const link = await prisma.webMagicLink.findUniqueOrThrow({ where: { tokenHash: input.tokenHash } });
    const winner = results.find((result) => result.isRight() && result.value !== null);
    expect(winner?.isRight() && winner.value?.sessionStartedAtMs).toBe(link.requestedAt.getTime());
    expect(await prisma.user.count({ where: { email } })).toBe(1);
    expect(await prisma.wallet.count({ where: { user: { email } } })).toBe(1);
    expect(await prisma.webMagicLink.count({ where: { email, consumedAt: { not: null } } })).toBe(1);
  });

  it('rejects expiry and replay while reusing an existing user', async () => {
    const email = `existing-${Date.now()}@example.com`;
    const user = await prisma.user.create({ data: { email, displayName: 'Existing' } });
    const tokenHash = createHash('sha256').update('existing-token').digest('hex');
    await repository.create({ email, tokenHash, consentGranted: true, activatedAt: new Date(), expiresAt: new Date(Date.now() + 600000) });

    const first = await repository.consume(tokenHash, new Date());
    const second = await repository.consume(tokenHash, new Date());
    const expiredHash = createHash('sha256').update('expired-token').digest('hex');
    await repository.create({ email, tokenHash: expiredHash, consentGranted: true, activatedAt: new Date(), expiresAt: new Date(Date.now() - 1) });
    const expired = await repository.consume(expiredHash, new Date());

    expect(first.isRight() && first.value?.user.id).toBe(user.id);
    expect(second.isRight() && second.value).toBeNull();
    expect(expired.isRight() && expired.value).toBeNull();
    expect(await prisma.user.count({ where: { email } })).toBe(1);
    expect(await prisma.wallet.count({ where: { user: { email } } })).toBe(1);
    expect((await prisma.user.findUniqueOrThrow({ where: { email } })).emailVerified).toBe(true);
  });

  it('does not consume an unactivated link or suspend an existing user', async () => {
    const email = `suspended-${Date.now()}@example.com`;
    const user = await prisma.user.create({ data: { email, displayName: 'Suspended', suspendedAt: new Date(), suspensionReason: 'fraud' } });
    const tokenHash = createHash('sha256').update('undelivered-token').digest('hex');
    await repository.create({ email, tokenHash, consentGranted: true, expiresAt: new Date(Date.now() + 600000) });

    const result = await repository.consume(tokenHash, new Date());

    expect(result.isRight() && result.value).toBeNull();
    expect(await prisma.webMagicLink.findUniqueOrThrow({ where: { tokenHash } })).toEqual(expect.objectContaining({ consumedAt: null, activatedAt: null }));
    expect(await prisma.user.findUniqueOrThrow({ where: { id: user.id } })).toEqual(expect.objectContaining({ suspendedAt: expect.any(Date) }));
  });

  it('rejects a delivered link for a suspended user before claiming it', async () => {
    const email = `locked-${Date.now()}@example.com`;
    await prisma.user.create({ data: { email, displayName: 'Locked', suspendedAt: new Date(), suspensionReason: 'fraud' } });
    const tokenHash = createHash('sha256').update('suspended-token').digest('hex');
    await repository.create({ email, tokenHash, consentGranted: true, activatedAt: new Date(), expiresAt: new Date(Date.now() + 600000) });

    const result = await repository.consume(tokenHash, new Date());

    expect(result.isRight() && result.value).toBeNull();
    expect(await prisma.webMagicLink.findUniqueOrThrow({ where: { tokenHash } })).toEqual(expect.objectContaining({ consumedAt: null }));
  });

  it('consumes a step-up proof once for the active user without creating a session, wallet, or consent', async () => {
    const email = `step-up-${Date.now()}@example.com`;
    const user = await prisma.user.create({ data: { email, displayName: 'Step Up' } });
    const tokenHash = createHash('sha256').update(randomBytes(32)).digest('hex');
    const beforeConsent = user.webConsentGrantedAt;
    await repository.create({ email, tokenHash, consentGranted: false, consentAt: null, activatedAt: new Date(), expiresAt: new Date(Date.now() + 600000) });

    const results = await Promise.all([
      repository.consumeStepUpProof(tokenHash, user.id, Date.now() - 1000, new Date()),
      repository.consumeStepUpProof(tokenHash, user.id, Date.now() - 1000, new Date()),
    ]);
    const accepted = results.filter((result) => result.isRight() && result.value);

    expect(accepted).toHaveLength(1);
    expect(await prisma.webMagicLink.count({ where: { tokenHash, consumedAt: { not: null } } })).toBe(1);
    expect(await prisma.user.findUniqueOrThrow({ where: { id: user.id } })).toMatchObject({ webConsentGrantedAt: beforeConsent, sessionsInvalidBefore: user.sessionsInvalidBefore });
    expect(await prisma.wallet.count({ where: { userId: user.id } })).toBe(0);
  });

  it('does not consume a step-up proof belonging to another account', async () => {
    const suffix = Date.now();
    const owner = await prisma.user.create({ data: { email: `step-owner-${suffix}@example.com`, displayName: 'Owner' } });
    const other = await prisma.user.create({ data: { email: `step-other-${suffix}@example.com`, displayName: 'Other' } });
    const tokenHash = createHash('sha256').update(randomBytes(32)).digest('hex');
    await repository.create({ email: owner.email, tokenHash, consentGranted: false, activatedAt: new Date(), expiresAt: new Date(Date.now() + 600000) });

    const wrongUser = await repository.consumeStepUpProof(tokenHash, other.id, Date.now() - 1000, new Date());
    const ownerUse = await repository.consumeStepUpProof(tokenHash, owner.id, Date.now() - 1000, new Date());

    expect(wrongUser.isRight() && wrongUser.value).toBe(false);
    expect(ownerUse.isRight() && ownerUse.value).toBe(true);
  });

  it.each(['expired', 'unactivated', 'consumed', 'suspended', 'deleted', 'cutoff'] as const)(
    'rejects a %s user/link without consuming its proof', async (state) => {
      const email = `step-${state}-${Date.now()}@example.com`;
      const user = await prisma.user.create({ data: {
        email, displayName: 'Step State',
        ...(state === 'suspended' ? { suspendedAt: new Date(), suspensionReason: 'test' } : {}),
        ...(state === 'deleted' ? { deletedAt: new Date() } : {}),
        ...(state === 'cutoff' ? { sessionsInvalidBefore: new Date() } : {}),
      } });
      const tokenHash = createHash('sha256').update(`${state}-${randomBytes(32).toString('hex')}`).digest('hex');
      await repository.create({
        email, tokenHash, consentGranted: false,
        activatedAt: state === 'unactivated' ? null : new Date(),
        expiresAt: state === 'expired' ? new Date(Date.now() - 1) : new Date(Date.now() + 600000),
        consumedAt: state === 'consumed' ? new Date() : null,
      });

      const result = await repository.consumeStepUpProof(tokenHash, user.id, Date.now() - 1000, new Date());

      expect(result.isRight() && result.value).toBe(false);
      expect(await prisma.webMagicLink.findUniqueOrThrow({ where: { tokenHash } })).toMatchObject({ consumedAt: state === 'consumed' ? expect.any(Date) : null });
    },
  );
});
