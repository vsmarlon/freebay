import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { VerifyPhoneUseCase } from './verify-phone.usecase';
import { UserDatabaseRepository } from '@/modules/users';
import { PhoneVerificationDatabaseRepository } from '../data/repositories/phone-verification-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { right } from '@/shared/core/either';
import {
  PhoneCodeAlreadyUsedError,
  PhoneCodeAttemptsExceededError,
  PhoneCodeExpiredError,
  PhoneCodeNotFoundError,
} from '@/shared/core/errors';

const mockPhoneVerificationRepository = {
  findLatestByUserId: jest.fn(),
  reserveFailedAttempt: jest.fn(),
  consumeAndVerify: jest.fn(),
  incrementAttempts: jest.fn(),
};

const mockUserRepository = { update: jest.fn() };

const mockPrisma = {
  post: { count: jest.fn() },
  product: { count: jest.fn() },
  story: { findFirst: jest.fn() },
};

const baseVerification = {
  id: 'code-1',
  userId: 'user-1',
  attempts: 0,
  maxAttempts: 5,
  usedAt: null as Date | null,
  expiresAt: new Date(Date.now() + 60_000),
  codeHash: '',
};

describe('VerifyPhoneUseCase', () => {
  let sut: VerifyPhoneUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VerifyPhoneUseCase,
        { provide: UserDatabaseRepository, useValue: mockUserRepository },
        { provide: PhoneVerificationDatabaseRepository, useValue: mockPhoneVerificationRepository },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get(VerifyPhoneUseCase);

    mockPrisma.post.count.mockResolvedValue(0);
    mockPrisma.product.count.mockResolvedValue(0);
    mockPrisma.story.findFirst.mockResolvedValue(null);
  });

  it('returns not-found when no code has been requested', async () => {
    mockPhoneVerificationRepository.findLatestByUserId.mockResolvedValue(right(null));
    const result = await sut.execute({ userId: 'user-1', code: '123456' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(PhoneCodeNotFoundError);
  });

  it('returns already-used when the code was previously consumed', async () => {
    mockPhoneVerificationRepository.findLatestByUserId.mockResolvedValue(
      right({ ...baseVerification, usedAt: new Date() }),
    );
    const result = await sut.execute({ userId: 'user-1', code: '123456' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(PhoneCodeAlreadyUsedError);
  });

  it('returns expired when past expiresAt', async () => {
    mockPhoneVerificationRepository.findLatestByUserId.mockResolvedValue(
      right({ ...baseVerification, expiresAt: new Date(Date.now() - 1000) }),
    );
    const result = await sut.execute({ userId: 'user-1', code: '123456' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(PhoneCodeExpiredError);
  });

  it('returns attempts-exceeded once maxAttempts is reached', async () => {
    mockPhoneVerificationRepository.findLatestByUserId.mockResolvedValue(
      right({ ...baseVerification, attempts: 5 }),
    );
    const result = await sut.execute({ userId: 'user-1', code: '123456' });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(PhoneCodeAttemptsExceededError);
  });

  it('increments attempts and returns not-found on a wrong code', async () => {
    const codeHash = await bcrypt.hash('999999', 10);
    mockPhoneVerificationRepository.findLatestByUserId.mockResolvedValue(
      right({ ...baseVerification, codeHash }),
    );
    mockPhoneVerificationRepository.reserveFailedAttempt.mockResolvedValue(right(true));
    const result = await sut.execute({ userId: 'user-1', code: '123456' });

    expect(mockPhoneVerificationRepository.reserveFailedAttempt).toHaveBeenCalledWith('code-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(PhoneCodeNotFoundError);
  });

  it('caps concurrent wrong-code attempts at the configured maximum through execute', async () => {
    const codeHash = await bcrypt.hash('999999', 10);
    let attempts = 0;
    mockPhoneVerificationRepository.findLatestByUserId.mockResolvedValue(
      right({ ...baseVerification, codeHash }),
    );
    mockPhoneVerificationRepository.reserveFailedAttempt.mockImplementation(async () => {
      if (attempts >= baseVerification.maxAttempts) return right(false);
      attempts += 1;
      return right(true);
    });
    mockPhoneVerificationRepository.incrementAttempts.mockImplementation(async () => {
      attempts += 1;
      return right({ ...baseVerification, attempts });
    });

    const results = await Promise.all(Array.from({ length: 10 }, () =>
      sut.execute({ userId: 'user-1', code: '123456' }),
    ));

    expect(attempts).toBe(baseVerification.maxAttempts);
    expect(mockPhoneVerificationRepository.reserveFailedAttempt).toHaveBeenCalledTimes(10);
    expect(results.filter((result) => result.isLeft() && result.value instanceof PhoneCodeAttemptsExceededError)).toHaveLength(5);
  });

  it('atomically consumes the code and verifies the user on a correct code', async () => {
    const codeHash = await bcrypt.hash('123456', 10);
    mockPhoneVerificationRepository.findLatestByUserId.mockResolvedValue(
      right({ ...baseVerification, codeHash }),
    );
    mockPhoneVerificationRepository.consumeAndVerify.mockResolvedValue(
      right({
        id: 'user-1',
        displayName: 'Test User',
        phoneVerified: true,
        isVerified: true,
        createdAt: new Date(),
      }),
    );

    const result = await sut.execute({ userId: 'user-1', code: '123456' });

    expect(mockPhoneVerificationRepository.consumeAndVerify).toHaveBeenCalledWith('code-1', 'user-1');
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.id).toBe('user-1');
    }
  });
});
