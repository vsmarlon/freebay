import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { prisma } from '../../../../test/setup-integration';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PhoneVerificationDatabaseRepository } from '../data/repositories/phone-verification-database.repository';
import { VerifyPhoneUseCase } from './verify-phone.usecase';

describe('VerifyPhoneUseCase integration', () => {
  let useCase: VerifyPhoneUseCase;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VerifyPhoneUseCase,
        PhoneVerificationDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    useCase = module.get(VerifyPhoneUseCase);
  });

  it('allows one concurrent correct-code verification and persists the user update atomically', async () => {
    const user = await prisma.user.create({ data: { email: `phone-usecase-${Date.now()}@example.com`, displayName: 'Phone use case', phone: '11999999999' } });
    const record = await prisma.phoneVerificationCode.create({ data: {
      userId: user.id,
      phone: '11999999999',
      codeHash: await bcrypt.hash('123456', 10),
      expiresAt: new Date(Date.now() + 60_000),
      maxAttempts: 5,
    } });

    const results = await Promise.all([
      useCase.execute({ userId: user.id, code: '123456' }),
      useCase.execute({ userId: user.id, code: '123456' }),
    ]);

    expect(results.filter((result) => result.isRight())).toHaveLength(1);
    expect(results.filter((result) => result.isLeft())).toHaveLength(1);
    expect(await prisma.user.findUniqueOrThrow({ where: { id: user.id } })).toEqual(expect.objectContaining({ phoneVerified: true, isVerified: true }));
    expect((await prisma.phoneVerificationCode.findUniqueOrThrow({ where: { id: record.id } })).usedAt).toEqual(expect.any(Date));
  });
});
