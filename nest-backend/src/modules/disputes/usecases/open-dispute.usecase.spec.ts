import { Test, TestingModule } from '@nestjs/testing';
import { OpenDisputeUseCase } from './open-dispute.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { DisputeRepository } from '../domain/repositories/dispute.repository';
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
        { provide: DisputeRepository, useValue: mockDisputeRepo },
        { provide: NotificationService, useValue: mockNotificationService },
      ],
    }).compile();

    sut = module.get<OpenDisputeUseCase>(OpenDisputeUseCase);
    jest.clearAllMocks();
  });

  it('should open a dispute successfully', async () => {
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

  it('should return NotFoundError when order not found', async () => {
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

  it('should return UnauthorizedError when user is not participant', async () => {
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

  it('should return BadRequestError when dispute already exists', async () => {
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

  it('should reject when more than 48 hours have passed since deliveryConfirmedAt', async () => {
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

  it('should fall back to order.createdAt when deliveryConfirmedAt is null, and still apply the 48h window', async () => {
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
});
