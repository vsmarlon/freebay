import { Test, TestingModule } from '@nestjs/testing';
import { OpenDisputeUseCase } from './open-dispute.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { DisputeDatabaseRepository } from '../data/repositories/dispute-database.repository';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { NotFoundError, BadRequestError, UnauthorizedError } from '@/shared/core/errors';
import { right } from '@/shared/core/either';

const mockNotificationService = {
  notifyDispute: jest.fn().mockResolvedValue(undefined),
  notifyOrderStatus: jest.fn().mockResolvedValue(undefined),
};

const mockPrisma = {
  order: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockDisputeRepo = {
  create: jest.fn(),
};

describe('OpenDisputeUseCase', () => {
  let sut: OpenDisputeUseCase;

  const mockOrder = {
    id: 'order-123',
    buyerId: 'buyer-123',
    sellerId: 'seller-123',
    status: 'DELIVERED',
    deliveryConfirmedAt: new Date(),
    createdAt: new Date(),
    dispute: null,
  };

  const mockDispute = {
    id: 'dispute-123',
    orderId: 'order-123',
    openedById: 'buyer-123',
    reason: 'Product not as described',
    status: 'OPEN',
    createdAt: new Date(),
    expiresAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OpenDisputeUseCase,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: DisputeDatabaseRepository, useValue: mockDisputeRepo },
        { provide: NotificationService, useValue: mockNotificationService },
      ],
    }).compile();

    sut = module.get<OpenDisputeUseCase>(OpenDisputeUseCase);
    jest.clearAllMocks();
    mockPrisma.$transaction.mockImplementation((work) => work({
      order: { updateMany: jest.fn().mockResolvedValue({ count: 1 }) },
    }));
  });

  it('opens a dispute successfully', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(mockOrder);
    mockDisputeRepo.create.mockResolvedValue(right(mockDispute));
    mockPrisma.order.update.mockResolvedValue({ ...mockOrder, status: 'DISPUTED' });

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'buyer-123',
      reason: 'Product not as described',
    });

    expect(result.isRight()).toBe(true);
  });

  it('returns NotFoundError when order not found', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(null);

    const result = await sut.execute({
      orderId: 'nonexistent',
      userId: 'buyer-123',
      reason: 'Test',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(NotFoundError);
    }
  });

  it('returns UnauthorizedError when user is not participant', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(mockOrder);

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'stranger-123',
      reason: 'Test',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(UnauthorizedError);
    }
  });

  it('returns BadRequestError when dispute already exists', async () => {
    mockPrisma.order.findUnique.mockResolvedValue({ ...mockOrder, dispute: mockDispute });

    const result = await sut.execute({
      orderId: 'order-123',
      userId: 'buyer-123',
      reason: 'Test',
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
    }
  });

  it('rejects when more than 48 hours have passed since deliveryConfirmedAt', async () => {
    const now = new Date('2026-01-03T00:00:00.000Z');
    const deliveryConfirmedAt = new Date(now.getTime() - 49 * 60 * 60 * 1000);
    mockPrisma.order.findUnique.mockResolvedValue({ ...mockOrder, deliveryConfirmedAt });

    const result = await sut.execute(
      { orderId: 'order-123', userId: 'buyer-123', reason: 'Too late' },
      now,
    );

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
    }
    expect(mockDisputeRepo.create).not.toHaveBeenCalled();
  });

  it('falls back to order.createdAt when deliveryConfirmedAt is null, and still applies the 48h window', async () => {
    const now = new Date('2026-01-03T00:00:00.000Z');
    const createdAt = new Date(now.getTime() - 49 * 60 * 60 * 1000);
    mockPrisma.order.findUnique.mockResolvedValue({ ...mockOrder, deliveryConfirmedAt: null, createdAt });

    const result = await sut.execute(
      { orderId: 'order-123', userId: 'buyer-123', reason: 'Too late' },
      now,
    );

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(BadRequestError);
    }
    expect(mockDisputeRepo.create).not.toHaveBeenCalled();
  });

  it('allows a stale SHIPPED order into manual dispute review without using order creation as delivery time', async () => {
    const now = new Date('2026-01-03T00:00:00.000Z');
    mockPrisma.order.findUnique.mockResolvedValue({
      ...mockOrder,
      status: 'SHIPPED',
      deliveryConfirmedAt: null,
      createdAt: new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000),
    });
    mockDisputeRepo.create.mockResolvedValue(right(mockDispute));
    mockPrisma.order.update.mockResolvedValue({ ...mockOrder, status: 'DISPUTED' });

    const result = await sut.execute(
      { orderId: 'order-123', userId: 'buyer-123', reason: 'Never arrived' },
      now,
    );

    expect(result.isRight()).toBe(true);
    expect(mockDisputeRepo.create).toHaveBeenCalled();
  });

  it('does not create a dispute when the atomic order claim loses to cancellation or release', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(mockOrder);
    mockDisputeRepo.create.mockResolvedValue(right(mockDispute));
    const orderUpdateMany = jest.fn().mockResolvedValue({ count: 0 });
    const disputeCreate = jest.fn();
    mockPrisma.$transaction.mockImplementation(async (work) => work({
      order: { updateMany: orderUpdateMany },
      dispute: { create: disputeCreate },
    }));

    const result = await sut.execute({
      orderId: 'order-123', userId: 'buyer-123', reason: 'Item not received',
    });

    expect(result.isLeft()).toBe(true);
    expect(orderUpdateMany).toHaveBeenCalled();
    expect(disputeCreate).not.toHaveBeenCalled();
  });
});
