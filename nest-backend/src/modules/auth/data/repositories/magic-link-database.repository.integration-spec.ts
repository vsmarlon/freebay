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

    expect(first.isRight() && first.value?.id).toBe(user.id);
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
});
