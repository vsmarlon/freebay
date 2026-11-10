import { Test, TestingModule } from '@nestjs/testing';
import { prisma } from '../../../../../test/setup-integration';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PhoneVerificationDatabaseRepository } from './phone-verification-database.repository';

describe('PhoneVerificationDatabaseRepository integration', () => {
  let repository: PhoneVerificationDatabaseRepository;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [PhoneVerificationDatabaseRepository, { provide: PrismaService, useValue: prisma }],
    }).compile();
    repository = module.get(PhoneVerificationDatabaseRepository);
  });

  it('reserves no more failed attempts than maxAttempts under concurrency', async () => {
    const user = await prisma.user.create({ data: { email: `phone-budget-${Date.now()}@example.com`, displayName: 'Phone budget' } });
    const record = await prisma.phoneVerificationCode.create({ data: {
      userId: user.id,
      phone: '11999999999',
      codeHash: 'test-hash',
      expiresAt: new Date(Date.now() + 60_000),
      maxAttempts: 5,
    } });

    const results = await Promise.all(Array.from({ length: 8 }, () => repository.reserveFailedAttempt(record.id)));

    expect(results.filter((result) => result.isRight() && result.value)).toHaveLength(5);
    expect((await prisma.phoneVerificationCode.findUniqueOrThrow({ where: { id: record.id } })).attempts).toBe(5);
  });

  it('consumes the code and verifies the user exactly once in one transaction', async () => {
    const user = await prisma.user.create({ data: { email: `phone-consume-${Date.now()}@example.com`, displayName: 'Phone consume', phone: '11999999999' } });
    const record = await prisma.phoneVerificationCode.create({ data: {
      userId: user.id,
      phone: '11999999999',
      codeHash: 'test-hash',
      expiresAt: new Date(Date.now() + 60_000),
      maxAttempts: 5,
    } });

    const results = await Promise.all([
      repository.consumeAndVerify(record.id, user.id),
      repository.consumeAndVerify(record.id, user.id),
    ]);

    expect(results.filter((result) => result.isRight() && result.value !== null)).toHaveLength(1);
    expect(results.filter((result) => result.isRight() && result.value === null)).toHaveLength(1);
    expect(await prisma.user.findUniqueOrThrow({ where: { id: user.id } })).toEqual(expect.objectContaining({ phoneVerified: true, isVerified: true }));
    expect((await prisma.phoneVerificationCode.findUniqueOrThrow({ where: { id: record.id } })).usedAt).toEqual(expect.any(Date));
  });

  it('does not consume an OTP for a phone number that is no longer current', async () => {
    const user = await prisma.user.create({ data: { email: `phone-changed-${Date.now()}@example.com`, displayName: 'Phone changed', phone: '1111111111' } });
    const record = await prisma.phoneVerificationCode.create({ data: {
      userId: user.id,
      phone: '1111111111',
      codeHash: 'test-hash',
      expiresAt: new Date(Date.now() + 60_000),
      maxAttempts: 5,
    } });

    await prisma.user.update({ where: { id: user.id }, data: { phone: '2222222222', phoneVerified: false, isVerified: false } });
    const result = await repository.consumeAndVerify(record.id, user.id);
    const persistedUser = await prisma.user.findUniqueOrThrow({ where: { id: user.id } });
    const persistedCode = await prisma.phoneVerificationCode.findUniqueOrThrow({ where: { id: record.id } });

    expect({
      phone: persistedUser.phone,
      phoneVerified: persistedUser.phoneVerified,
      isVerified: persistedUser.isVerified,
      otpConsumed: persistedCode.usedAt !== null,
      returnedUser: result.isRight() && result.value !== null,
    }).toEqual({ phone: '2222222222', phoneVerified: false, isVerified: false, otpConsumed: false, returnedUser: false });
  });
});
