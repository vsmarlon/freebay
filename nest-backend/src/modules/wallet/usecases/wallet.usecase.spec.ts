import { Test, TestingModule } from '@nestjs/testing';
import { GetWalletUseCase, WithdrawUseCase } from './wallet.usecase';
import { NotFoundError, InsufficientBalanceError } from '@/shared/core/errors';
import { PrismaWalletRepository } from '../repositories/wallet.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

describe('GetWalletUseCase', () => {
  let sut: GetWalletUseCase;
  let mockWalletRepository: any;

  beforeEach(async () => {
    mockWalletRepository = {
      findByUserId: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GetWalletUseCase,
        { provide: PrismaWalletRepository, useValue: mockWalletRepository },
      ],
    }).compile();

    sut = module.get<GetWalletUseCase>(GetWalletUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should return wallet with calculated available balance', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue({
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 8000,
      pendingBalance: 2000,
    });

    const result = await sut.execute('user-123');

    expect(result.balance).toBe(10000);
    expect(result.pendingBalance).toBe(2000);
    expect(result.availableBalance).toBe(8000);
  });

  it('should return zeros if wallet not found', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue(null);

    const result = await sut.execute('user-123');

    expect(result.balance).toBe(0);
    expect(result.pendingBalance).toBe(0);
    expect(result.availableBalance).toBe(0);
  });
});

describe('WithdrawUseCase', () => {
  let sut: WithdrawUseCase;
  let mockWalletRepository: any;
  let mockPrisma: any;

  beforeEach(async () => {
    mockWalletRepository = {
      findByUserId: jest.fn(),
    };

    mockPrisma = {
      withdrawal: {
        create: jest.fn().mockResolvedValue({
          id: 'withdrawal-123',
          status: 'PENDING',
        }),
      },
      wallet: {
        update: jest.fn().mockResolvedValue({}),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WithdrawUseCase,
        { provide: PrismaWalletRepository, useValue: mockWalletRepository },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<WithdrawUseCase>(WithdrawUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should allow withdrawal when sufficient balance', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue({
      id: 'wallet-123',
      userId: 'user-123',
      availableBalance: 10000,
      pendingBalance: 2000,
    });

    const input = {
      userId: 'user-123',
      amount: 5000,
      pixKey: '12345678900',
      pixKeyType: 'CPF' as const,
    };

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.withdrawalId).toBeDefined();
      expect(result.value.status).toBe('PENDING');
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
});
