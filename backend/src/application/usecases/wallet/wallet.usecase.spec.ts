import { GetWalletUseCase, WithdrawUseCase } from './wallet.usecase';
import { IWalletRepository } from '@/domain/repositories';
import { WalletEntity } from '@/domain/entities';

const mockWalletRepository: jest.Mocked<IWalletRepository> = {
  findByUserId: jest.fn(),
  create: jest.fn(),
  updateBalance: jest.fn(),
  setRecipientId: jest.fn(),
};

const mockWallet: WalletEntity = {
  id: 'wallet-1',
  userId: 'user-1',
  availableBalance: 50000,
  pendingBalance: 10000,
  totalEarned: 100000,
  recipientId: 'rec-1',
};

describe('GetWalletUseCase', () => {
  let sut: GetWalletUseCase;

  beforeEach(() => {
    sut = new GetWalletUseCase(mockWalletRepository);
    jest.clearAllMocks();
  });

  it('should return existing wallet', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue(mockWallet);

    const result = await sut.execute('user-1');

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.id).toBe('wallet-1');
      expect(result.value.availableBalance).toBe(50000);
    }
  });

  it('should auto-create wallet when not found', async () => {
    const newWallet: WalletEntity = {
      id: 'wallet-new',
      userId: 'user-2',
      availableBalance: 0,
      pendingBalance: 0,
      totalEarned: 0,
      recipientId: null,
    };

    mockWalletRepository.findByUserId.mockResolvedValue(null);
    mockWalletRepository.create.mockResolvedValue(newWallet);

    const result = await sut.execute('user-2');

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.id).toBe('wallet-new');
      expect(result.value.availableBalance).toBe(0);
    }
    expect(mockWalletRepository.create).toHaveBeenCalledWith('user-2');
  });
});

describe('WithdrawUseCase', () => {
  let sut: WithdrawUseCase;

  beforeEach(() => {
    sut = new WithdrawUseCase(mockWalletRepository);
    jest.clearAllMocks();
  });

  it('should return left(NotFoundError) when wallet not found', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue(null);

    const result = await sut.execute('user-1', 1000);

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('NOT_FOUND');
    }
  });

  it('should return left(InsufficientBalanceError) when balance too low', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue({
      ...mockWallet,
      availableBalance: 500,
    });

    const result = await sut.execute('user-1', 1000);

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('INSUFFICIENT_BALANCE');
    }
  });

  it('should return left(NoRecipientError) when no recipient configured', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue({
      ...mockWallet,
      recipientId: null,
    });

    const result = await sut.execute('user-1', 1000);

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('NO_RECIPIENT');
    }
  });

  it('should withdraw successfully and return updated wallet', async () => {
    mockWalletRepository.findByUserId.mockResolvedValue(mockWallet);
    const updatedWallet = { ...mockWallet, availableBalance: 49000 };
    mockWalletRepository.updateBalance.mockResolvedValue(updatedWallet);

    const result = await sut.execute('user-1', 1000);

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.availableBalance).toBe(49000);
    }
    expect(mockWalletRepository.updateBalance).toHaveBeenCalledWith('user-1', {
      availableBalance: 49000,
    });
  });
});
