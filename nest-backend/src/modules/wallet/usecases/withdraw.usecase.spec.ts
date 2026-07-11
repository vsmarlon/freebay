import { Test, TestingModule } from '@nestjs/testing';
import { WithdrawUseCase } from './withdraw.usecase';
import { NotFoundError, InsufficientBalanceError } from '@/shared/core/errors';
import { WalletRepository } from '../domain/repositories/wallet.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

type MockPrisma = Record<string, Record<string, jest.Mock> | jest.Mock>;

describe('WithdrawUseCase', () => {
  let sut: WithdrawUseCase;
  let mockWalletRepository: any;
  let mockPrisma: MockPrisma;

  beforeEach(async () => {
    mockWalletRepository = {
      findByUserId: jest.fn(),
    } as jest.Mocked<Partial<WalletRepository>>;

    mockPrisma = {
      $transaction: jest.fn().mockImplementation((cb) => cb(mockPrisma)),
      $queryRaw: jest.fn().mockImplementation(async (queryParts, userId) => {
        const wallet = await mockWalletRepository.findByUserId(userId);
        return wallet ? [wallet] : [];
      }),
      withdrawal: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({
          id: 'withdrawal-123',
          status: 'PENDING',
        }),
      },
      wallet: {
        update: jest.fn().mockResolvedValue({}),
      },
    } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WithdrawUseCase,
        { provide: WalletRepository, useValue: mockWalletRepository },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<WithdrawUseCase>(WithdrawUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should allow withdrawal when sufficient balance', async () => {
    const wallet = {
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 10000,
      pendingBalance: 2000,
      totalEarned: 0,
      recipientId: null,
      createdAt: new Date(),
    };
    const createdWithdrawal = {
      id: 'withdrawal-123',
      walletId: 'wallet-123',
      amount: 5000,
      status: 'PENDING',
      idempotencyKey: null,
      createdAt: new Date(),
    };
    (mockPrisma as any).$queryRaw = jest.fn().mockResolvedValue([wallet]);
    (mockPrisma.withdrawal as any).create = jest.fn().mockResolvedValue(createdWithdrawal);
    (mockPrisma.wallet as any).update = jest.fn().mockResolvedValue({});

    const input = {
      userId: 'user-123',
      amount: 5000,
      pixKey: '12345678900',
      pixKeyType: 'CPF' as const,
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.id).toBe('withdrawal-123');
      expect(result.value.status).toBe('PENDING');
      expect(result.value.amount).toBe(5000);
    }
  });

  it('should return error if wallet not found', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue(null);

    const input = {
      userId: 'user-123',
      amount: 5000,
      pixKey: '12345678900',
      pixKeyType: 'CPF' as const,
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });

  it('should return error if insufficient available balance', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue({
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 1000,
      pendingBalance: 4000,
    });

    const input = {
      userId: 'user-123',
      amount: 2000,
      pixKey: '12345678900',
      pixKeyType: 'CPF' as const,
    };

    const result = await sut.execute(input);

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(InsufficientBalanceError);
    }
  });

  it('should return error if amount equals available balance', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue({
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 5000,
      pendingBalance: 0,
    });

    const input = {
      userId: 'user-123',
      amount: 5000,
      pixKey: '12345678900',
      pixKeyType: 'CPF' as const,
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
  });

  it('should allow withdrawal with EMAIL pix key type', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue({
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 10000,
      pendingBalance: 0,
    });

    const input = {
      userId: 'user-123',
      amount: 5000,
      pixKey: 'user@example.com',
      pixKeyType: 'EMAIL' as const,
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
  });

  it('should allow withdrawal with PHONE pix key type', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue({
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 10000,
      pendingBalance: 0,
    });

    const input = {
      userId: 'user-123',
      amount: 5000,
      pixKey: '+5511999999999',
      pixKeyType: 'PHONE' as const,
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
  });

  it('should allow withdrawal with RANDOM pix key type', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue({
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 10000,
      pendingBalance: 0,
    });

    const input = {
      userId: 'user-123',
      amount: 5000,
      pixKey: '12345678-1234-5678-1234-567812345678',
      pixKeyType: 'RANDOM' as const,
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
  });

  it('should return existing withdrawal if idempotencyKey already exists', async () => {
    const existingWithdrawal = {
      id: 'existing-withdrawal-id',
      walletId: 'wallet-123',
      status: 'PENDING',
      amount: 5000,
      idempotencyKey: 'dup-key-123',
      createdAt: new Date(),
    };
    mockWalletRepository.findWithdrawalByIdempotencyKey = jest.fn().mockResolvedValue(
      { isRight: () => true, value: existingWithdrawal },
    );

    const input = {
      userId: 'user-123',
      amount: 5000,
      pixKey: 'user@example.com',
      pixKeyType: 'EMAIL' as const,
      idempotencyKey: 'dup-key-123',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.id).toBe('existing-withdrawal-id');
      expect(result.value.status).toBe('PENDING');
      expect(result.value.amount).toBe(5000);
    }
    expect(mockWalletRepository.findWithdrawalByIdempotencyKey).toHaveBeenCalledWith('dup-key-123');
  });

  it('should return existing withdrawal if concurrency race condition returns unique key constraint error', async () => {
    const wallet = {
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 10000,
      pendingBalance: 0,
      totalEarned: 0,
      recipientId: null,
      createdAt: new Date(),
    };
    const existingWithdrawal = {
      id: 'raced-withdrawal-id',
      walletId: 'wallet-123',
      status: 'PENDING',
      amount: 5000,
      idempotencyKey: 'race-key-123',
      createdAt: new Date(),
    };

    mockWalletRepository.findWithdrawalByIdempotencyKey = jest.fn()
      .mockResolvedValueOnce({ isRight: () => true, value: null })
      .mockResolvedValueOnce({ isRight: () => true, value: existingWithdrawal });

    (mockPrisma as any).$queryRaw = jest.fn().mockResolvedValue([wallet]);
    (mockPrisma.withdrawal as any).create = jest.fn().mockRejectedValue({
      code: 'P2002',
      message: 'Unique constraint failed on the fields: (idempotencyKey)',
    });

    const input = {
      userId: 'user-123',
      amount: 5000,
      pixKey: 'user@example.com',
      pixKeyType: 'EMAIL' as const,
      idempotencyKey: 'race-key-123',
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.id).toBe('raced-withdrawal-id');
      expect(result.value.status).toBe('PENDING');
      expect(result.value.amount).toBe(5000);
    }
  });
});
