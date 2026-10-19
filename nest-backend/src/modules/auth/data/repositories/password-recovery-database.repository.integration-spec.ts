import { Test, TestingModule } from '@nestjs/testing';
import { prisma } from '../../../../../test/setup-integration';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PasswordRecoveryDatabaseRepository } from './password-recovery-database.repository';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';
import { createHash, randomBytes } from 'node:crypto';
import { UserDatabaseRepository } from '@/modules/users';
import { SessionRevokerService } from '@/shared/auth/session-revoker.service';
import { VerifyPasswordRecoveryCodeUseCase } from '../../usecases/verify-password-recovery-code.usecase';
import { ResetPasswordUseCase } from '../../usecases/reset-password.usecase';
import { ResetWebPasswordUseCase } from '../../usecases/reset-web-password.usecase';

describe('PasswordRecoveryDatabaseRepository integration', () => {
  let repository: PasswordRecoveryDatabaseRepository;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PasswordRecoveryDatabaseRepository,
        AuthSessionStateDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    repository = module.get(PasswordRecoveryDatabaseRepository);
  });

  it('reserves no more than maxAttempts under concurrent recovery-code checks', async () => {
    const email = `recovery-budget-${Date.now()}@example.com`;
    const user = await prisma.user.create({ data: { email, displayName: 'Recovery budget' } });
    const record = await prisma.passwordRecoveryCode.create({ data: {
      userId: user.id,
      codeHash: 'test-hash',
      expiresAt: new Date(Date.now() + 60_000),
      maxAttempts: 5,
    } });

    const reservations = await Promise.all(Array.from({ length: 8 }, () => repository.reserveAttempt(record.id)));

    expect(reservations.filter((result) => result.isRight() && result.value)).toHaveLength(5);
    expect((await prisma.passwordRecoveryCode.findUniqueOrThrow({ where: { id: record.id } })).attempts).toBe(5);
  });

  it('atomically consumes a recovery code with exactly one password update', async () => {
    const email = `recovery-consume-${Date.now()}@example.com`;
    const user = await prisma.user.create({ data: { email, displayName: 'Recovery consume', passwordHash: 'old-hash' } });
    const record = await prisma.passwordRecoveryCode.create({ data: {
      userId: user.id,
      codeHash: 'test-hash',
      expiresAt: new Date(Date.now() + 60_000),
      maxAttempts: 5,
    } });

    const results = await Promise.all([
      repository.consumeAndUpdatePassword(record.id, user.id, 'new-hash-a'),
      repository.consumeAndUpdatePassword(record.id, user.id, 'new-hash-b'),
    ]);

    expect(results.filter((result) => result.isRight() && result.value)).toHaveLength(1);
    expect(results.filter((result) => result.isRight() && !result.value)).toHaveLength(1);
    expect(await prisma.user.findUniqueOrThrow({ where: { id: user.id } })).toEqual(expect.objectContaining({ passwordHash: expect.stringMatching(/^new-hash-[ab]$/) }));
    expect((await prisma.passwordRecoveryCode.findUniqueOrThrow({ where: { id: record.id } })).usedAt).toEqual(expect.any(Date));
  });

  it('atomically consumes a web-reset credential once and advances the durable session cutoff', async () => {
    const email = `web-reset-${Date.now()}@example.com`;
    const user = await prisma.user.create({ data: { email, displayName: 'Web reset', passwordHash: 'old-hash' } });
    const recovery = await prisma.passwordRecoveryCode.create({ data: {
      userId: user.id,
      codeHash: 'web-reset:' + 'a'.repeat(64),
      expiresAt: new Date(Date.now() + 60_000),
      maxAttempts: 5,
    } });
    const cutoffBefore = (await prisma.user.findUniqueOrThrow({ where: { id: user.id } })).sessionsInvalidBefore;
    const found = await repository.findByCodeHash(recovery.codeHash);
    expect(found.isRight() && found.value?.id).toBe(recovery.id);

    const results = await Promise.all([
      repository.consumeAndUpdatePassword(recovery.id, user.id, 'new-web-hash-a'),
      repository.consumeAndUpdatePassword(recovery.id, user.id, 'new-web-hash-b'),
    ]);

    expect(results.filter((result) => result.isRight() && result.value)).toHaveLength(1);
    expect(results.filter((result) => result.isRight() && !result.value)).toHaveLength(1);
    const updatedUser = await prisma.user.findUniqueOrThrow({ where: { id: user.id } });
    expect(updatedUser.passwordHash).toMatch(/^new-web-hash-[ab]$/);
    expect(updatedUser.sessionsInvalidBefore?.getTime()).toBeGreaterThan(cutoffBefore?.getTime() ?? 0);
    expect((await prisma.passwordRecoveryCode.findUniqueOrThrow({ where: { id: recovery.id } })).usedAt).toEqual(expect.any(Date));
    const replay = await repository.consumeAndUpdatePassword(recovery.id, user.id, 'replay-hash');
    expect(replay.isRight() && replay.value).toBe(false);
  });

  it('does not let legacy recovery attempts exhaust a web-reset credential before its owner consumes it', async () => {
    const email = `web-reset-purpose-${Date.now()}@example.com`;
    const token = randomBytes(32).toString('base64url');
    const codeHash = `web-reset:${createHash('sha256').update(token).digest('hex')}`;
    const user = await prisma.user.create({ data: { email, displayName: 'Web reset purpose', passwordHash: 'old-hash' } });
    const record = await prisma.passwordRecoveryCode.create({ data: {
      userId: user.id,
      codeHash,
      expiresAt: new Date(Date.now() + 60_000),
      maxAttempts: 5,
    } });
    const module = await Test.createTestingModule({
      providers: [
        VerifyPasswordRecoveryCodeUseCase,
        ResetPasswordUseCase,
        ResetWebPasswordUseCase,
        PasswordRecoveryDatabaseRepository,
        AuthSessionStateDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
        { provide: UserDatabaseRepository, useValue: { findByEmail: jest.fn() } },
        { provide: SessionRevokerService, useValue: { revokeAllSessions: jest.fn().mockResolvedValue(undefined) } },
      ],
    }).compile();
    const verifyLegacy = module.get(VerifyPasswordRecoveryCodeUseCase);
    const resetLegacy = module.get(ResetPasswordUseCase);

    const wrongPurposeAttempts = await Promise.all([
      ...Array.from({ length: 5 }, () => verifyLegacy.execute({ email, code: '123456' })),
      ...Array.from({ length: 5 }, () => resetLegacy.execute({ email, code: '123456', newPassword: 'attacker-password' })),
    ]);

    expect(wrongPurposeAttempts.every((result) => result.isLeft())).toBe(true);
    expect((await prisma.passwordRecoveryCode.findUniqueOrThrow({ where: { id: record.id } })).attempts).toBe(0);

    const reset = await module.get(ResetWebPasswordUseCase).execute({ token, newPassword: 'owner-new-password' });

    expect(reset.isRight()).toBe(true);
    expect((await prisma.passwordRecoveryCode.findUniqueOrThrow({ where: { id: record.id } })).attempts).toBe(1);
    expect((await prisma.passwordRecoveryCode.findUniqueOrThrow({ where: { id: record.id } })).usedAt).toEqual(expect.any(Date));
    expect((await prisma.user.findUniqueOrThrow({ where: { id: user.id } })).passwordHash).not.toBe('old-hash');
  });
});
