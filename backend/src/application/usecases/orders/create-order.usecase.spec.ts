import { CreateOrderUseCase, ConfirmDeliveryUseCase } from './create-order.usecase';
import { IOrderRepository, IWalletRepository } from '@/domain/repositories';
import { OrderEntity } from '@/domain/entities';
import { WalletEntity } from '@/domain/entities';

const mockOrderRepository: jest.Mocked<IOrderRepository> = {
  findById: jest.fn(),
  findByBuyerId: jest.fn(),
  findBySellerId: jest.fn(),
  create: jest.fn(),
  update: jest.fn(),
};

const mockWalletRepository: jest.Mocked<IWalletRepository> = {
  findByUserId: jest.fn(),
  create: jest.fn(),
  updateBalance: jest.fn(),
  setRecipientId: jest.fn(),
};

describe('CreateOrderUseCase', () => {
  let sut: CreateOrderUseCase;

  beforeEach(() => {
    sut = new CreateOrderUseCase(mockOrderRepository, mockWalletRepository);
    jest.clearAllMocks();
  });

  it('should create an order with correct fee calculation', async () => {
    const createdOrder: OrderEntity = {
      id: 'order-1',
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'prod-1',
      amount: 10000,
      platformFee: 1000,
      sellerAmount: 9000,
      status: 'PENDING',
      escrowStatus: 'HELD',
      meetingScheduledAt: null,
      deliveryConfirmedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    mockOrderRepository.create.mockResolvedValue(createdOrder);

    const result = await sut.execute({
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'prod-1',
      amount: 10000,
      platformFeePercent: 10,
    });

    expect(result._tag).toBe('right');
    expect(mockOrderRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({
        amount: 10000,
        platformFee: 1000,
        sellerAmount: 9000,
        status: 'PENDING',
        escrowStatus: 'HELD',
      }),
    );
  });

  it('should round platform fee correctly', async () => {
    const createdOrder: OrderEntity = {
      id: 'order-2',
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'prod-1',
      amount: 999,
      platformFee: 100,
      sellerAmount: 899,
      status: 'PENDING',
      escrowStatus: 'HELD',
      meetingScheduledAt: null,
      deliveryConfirmedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    mockOrderRepository.create.mockResolvedValue(createdOrder);

    await sut.execute({
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'prod-1',
      amount: 999,
      platformFeePercent: 10,
    });

    // Math.round(999 * 0.1) = 100
    expect(mockOrderRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({
        platformFee: 100,
        sellerAmount: 899,
      }),
    );
  });
});

describe('ConfirmDeliveryUseCase', () => {
  let sut: ConfirmDeliveryUseCase;

  beforeEach(() => {
    sut = new ConfirmDeliveryUseCase(mockOrderRepository, mockWalletRepository);
    jest.clearAllMocks();
  });

  it('should return left(NotFoundError) when order not found', async () => {
    mockOrderRepository.findById.mockResolvedValue(null);

    const result = await sut.execute('order-1', 'buyer-1');

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('NOT_FOUND');
    }
  });

  it('should return left(ForbiddenError) when caller is not the buyer', async () => {
    const order: OrderEntity = {
      id: 'order-1',
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'prod-1',
      amount: 10000,
      platformFee: 1000,
      sellerAmount: 9000,
      status: 'CONFIRMED',
      escrowStatus: 'HELD',
      meetingScheduledAt: null,
      deliveryConfirmedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    mockOrderRepository.findById.mockResolvedValue(order);

    const result = await sut.execute('order-1', 'not-the-buyer');

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('FORBIDDEN');
    }
  });

  it('should return left(InvalidOrderStateError) when order is not CONFIRMED', async () => {
    const order: OrderEntity = {
      id: 'order-1',
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'prod-1',
      amount: 10000,
      platformFee: 1000,
      sellerAmount: 9000,
      status: 'PENDING',
      escrowStatus: 'HELD',
      meetingScheduledAt: null,
      deliveryConfirmedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    mockOrderRepository.findById.mockResolvedValue(order);

    const result = await sut.execute('order-1', 'buyer-1');

    expect(result._tag).toBe('left');
    if (result._tag === 'left') {
      expect(result.value.code).toBe('INVALID_ORDER_STATE');
    }
  });

  it('should complete order and release escrow on success', async () => {
    const order: OrderEntity = {
      id: 'order-1',
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'prod-1',
      amount: 10000,
      platformFee: 1000,
      sellerAmount: 9000,
      status: 'CONFIRMED',
      escrowStatus: 'HELD',
      meetingScheduledAt: null,
      deliveryConfirmedAt: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const wallet: WalletEntity = {
      id: 'wallet-1',
      userId: 'seller-1',
      availableBalance: 0,
      pendingBalance: 9000,
      totalEarned: 0,
      recipientId: 'rec-1',
    };

    const updatedOrder = {
      ...order,
      status: 'COMPLETED' as const,
      escrowStatus: 'RELEASED' as const,
    };

    mockOrderRepository.findById.mockResolvedValue(order);
    mockOrderRepository.update.mockResolvedValue(updatedOrder);
    mockWalletRepository.findByUserId.mockResolvedValue(wallet);
    mockWalletRepository.updateBalance.mockResolvedValue({
      ...wallet,
      availableBalance: 9000,
      pendingBalance: 0,
      totalEarned: 9000,
    });

    const result = await sut.execute('order-1', 'buyer-1');

    expect(result._tag).toBe('right');
    expect(mockOrderRepository.update).toHaveBeenCalledWith(
      'order-1',
      expect.objectContaining({
        status: 'COMPLETED',
        escrowStatus: 'RELEASED',
      }),
    );
    expect(mockWalletRepository.updateBalance).toHaveBeenCalledWith('seller-1', {
      pendingBalance: 0,
      availableBalance: 9000,
      totalEarned: 9000,
    });
  });
});
