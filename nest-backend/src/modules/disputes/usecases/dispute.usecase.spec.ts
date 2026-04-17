import { Test, TestingModule } from '@nestjs/testing';
import { OpenDisputeUseCase, GetDisputeUseCase, GetUserDisputesUseCase, SubmitEvidenceUseCase, ResolveDisputeUseCase } from './dispute.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotFoundError, BadRequestError, UnauthorizedError } from '@/shared/core/errors';

jest.mock('@/shared/infra/prisma/prisma.service');

const mockPrisma = {
  $transaction: jest.fn((callback) => {
    const tx = {
      dispute: { update: jest.fn().mockResolvedValue({}) },
      order: { update: jest.fn().mockResolvedValue({}) },
      wallet: { findUnique: jest.fn().mockResolvedValue({ userId: 'buyer-123' }), update: jest.fn().mockResolvedValue({}) },
    };
    return callback(tx);
  }),
  order: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  dispute: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
  },
};

describe('Disputes UseCases', () => {
  let openDisputeUseCase: OpenDisputeUseCase;
  let getDisputeUseCase: GetDisputeUseCase;
  let getUserDisputesUseCase: GetUserDisputesUseCase;
  let submitEvidenceUseCase: SubmitEvidenceUseCase;
  let resolveDisputeUseCase: ResolveDisputeUseCase;

  const mockOrder = {
    id: 'order-123',
    buyerId: 'buyer-123',
    sellerId: 'seller-123',
    status: 'DELIVERED',
    deliveryConfirmedAt: new Date(),
    dispute: null,
  };

  const mockDispute = {
    id: 'dispute-123',
    orderId: 'order-123',
    openedById: 'buyer-123',
    reason: 'Product not as described',
    status: 'OPEN',
    createdAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OpenDisputeUseCase,
        GetDisputeUseCase,
        GetUserDisputesUseCase,
        SubmitEvidenceUseCase,
        ResolveDisputeUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    openDisputeUseCase = module.get<OpenDisputeUseCase>(OpenDisputeUseCase);
    getDisputeUseCase = module.get<GetDisputeUseCase>(GetDisputeUseCase);
    getUserDisputesUseCase = module.get<GetUserDisputesUseCase>(GetUserDisputesUseCase);
    submitEvidenceUseCase = module.get<SubmitEvidenceUseCase>(SubmitEvidenceUseCase);
    resolveDisputeUseCase = module.get<ResolveDisputeUseCase>(ResolveDisputeUseCase);

    jest.clearAllMocks();
  });

  describe('OpenDisputeUseCase', () => {
    it('should open a dispute successfully', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(mockOrder);
      mockPrisma.dispute.create.mockResolvedValue(mockDispute);
      mockPrisma.order.update.mockResolvedValue({ ...mockOrder, status: 'DISPUTED' });

      const result = await openDisputeUseCase.execute({
        orderId: 'order-123',
        userId: 'buyer-123',
        reason: 'Product not as described',
      });

      expect(result.isRight()).toBe(true);
    });

    it('should return NotFoundError when order not found', async () => {
      mockPrisma.order.findUnique.mockResolvedValue(null);

      const result = await openDisputeUseCase.execute({
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

      const result = await openDisputeUseCase.execute({
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

      const result = await openDisputeUseCase.execute({
        orderId: 'order-123',
        userId: 'buyer-123',
        reason: 'Test',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(BadRequestError);
      }
    });
  });

  describe('GetDisputeUseCase', () => {
    it('should return dispute when found', async () => {
      const disputeWithOrder = {
        ...mockDispute,
        order: { ...mockOrder, buyer: { id: 'buyer-123', displayName: 'Buyer', avatarUrl: null }, seller: { id: 'seller-123', displayName: 'Seller', avatarUrl: null }, product: {} },
        openedBy: { id: 'buyer-123', displayName: 'Buyer' },
      };
      mockPrisma.dispute.findUnique.mockResolvedValue(disputeWithOrder);

      const result = await getDisputeUseCase.execute('dispute-123', 'buyer-123');

      expect(result.isRight()).toBe(true);
    });

    it('should return NotFoundError when dispute not found', async () => {
      mockPrisma.dispute.findUnique.mockResolvedValue(null);

      const result = await getDisputeUseCase.execute('nonexistent', 'buyer-123');

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(NotFoundError);
      }
    });
  });

  describe('GetUserDisputesUseCase', () => {
    it('should return user disputes', async () => {
      mockPrisma.dispute.findMany.mockResolvedValue([mockDispute]);

      const result = await getUserDisputesUseCase.execute('buyer-123');

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value).toHaveLength(1);
      }
    });
  });

  describe('SubmitEvidenceUseCase', () => {
    it('should submit evidence successfully', async () => {
      mockPrisma.dispute.findUnique.mockResolvedValue({
        ...mockDispute,
        order: mockOrder,
      });
      mockPrisma.dispute.update.mockResolvedValue({ ...mockDispute, status: 'AWAITING_SELLER' });

      const result = await submitEvidenceUseCase.execute({
        disputeId: 'dispute-123',
        userId: 'buyer-123',
        evidence: { message: 'Evidence here' },
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.submitted).toBe(true);
      }
    });

    it('should return NotFoundError when dispute not found', async () => {
      mockPrisma.dispute.findUnique.mockResolvedValue(null);

      const result = await submitEvidenceUseCase.execute({
        disputeId: 'nonexistent',
        userId: 'buyer-123',
        evidence: {},
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(NotFoundError);
      }
    });
  });

  describe('ResolveDisputeUseCase', () => {
    it('should resolve dispute in favor of buyer', async () => {
      mockPrisma.dispute.findUnique.mockResolvedValue({
        ...mockDispute,
        order: mockOrder,
      });

      const result = await resolveDisputeUseCase.execute({
        disputeId: 'dispute-123',
        resolution: 'Refund granted',
        winner: 'BUYER',
      });

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.resolved).toBe(true);
      }
    });

    it('should return NotFoundError when dispute not found', async () => {
      mockPrisma.dispute.findUnique.mockResolvedValue(null);

      const result = await resolveDisputeUseCase.execute({
        disputeId: 'nonexistent',
        resolution: 'Test',
        winner: 'BUYER',
      });

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value).toBeInstanceOf(NotFoundError);
      }
    });
  });
});
