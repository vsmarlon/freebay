import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import { VerifyPhoneUseCase } from './verify-phone.usecase';
import { UserRepository } from '@/modules/auth/domain/repositories/user.repository';
import { PhoneVerificationRepository } from '../domain/repositories/phone-verification.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { right } from '@/shared/core/either';
import {
  PhoneCodeAlreadyUsedError,
  PhoneCodeAttemptsExceededError,
  PhoneCodeExpiredError,
  PhoneCodeNotFoundError,
} from '@/shared/core/errors';

const mockUserRepository = {
  update: jest.fn(),
};

const mockPhoneVerificationRepository = {
  findLatestByUserId: jest.fn(),
  incrementAttempts: jest.fn(),
  markUsed: jest.fn(),
};

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
        { provide: UserRepository, useValue: mockUserRepository },
        { provide: PhoneVerificationRepository, useValue: mockPhoneVerificationRepository },
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
    const result = await sut.execute({ userId: 'user-1', code: '123456' });

    expect(mockPhoneVerificationRepository.incrementAttempts).toHaveBeenCalledWith('code-1');
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(PhoneCodeNotFoundError);
  });

  it('marks the code used, verifies the user, and returns the mapped profile on a correct code', async () => {
    const codeHash = await bcrypt.hash('123456', 10);
    mockPhoneVerificationRepository.findLatestByUserId.mockResolvedValue(
      right({ ...baseVerification, codeHash }),
    );
    mockPhoneVerificationRepository.markUsed.mockResolvedValue(right({ ...baseVerification, usedAt: new Date() }));
    mockUserRepository.update.mockResolvedValue(
      right({
        id: 'user-1',
        displayName: 'Test User',
        phoneVerified: true,
        isVerified: true,
        createdAt: new Date(),
      }),
    );

    const result = await sut.execute({ userId: 'user-1', code: '123456' });

    expect(mockPhoneVerificationRepository.markUsed).toHaveBeenCalledWith('code-1');
    expect(mockUserRepository.update).toHaveBeenCalledWith('user-1', {
      phoneVerified: true,
      isVerified: true,
    });
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.id).toBe('user-1');
    }
  });
});
