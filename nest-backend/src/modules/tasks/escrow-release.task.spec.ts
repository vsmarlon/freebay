import { Test, TestingModule } from '@nestjs/testing';
import { EscrowReleaseTask } from './escrow-release.task';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

const mockPrisma = {
  order: {
    findMany: jest.fn(),
    update: jest.fn(),
  },
  wallet: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  transaction: {
    update: jest.fn(),
  },
  $transaction: jest.fn(),
};

describe('EscrowReleaseTask', () => {
  let sut: EscrowReleaseTask;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EscrowReleaseTask,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<EscrowReleaseTask>(EscrowReleaseTask);
    jest.clearAllMocks();
  });

  it('should release escrow for orders delivered over 7 days ago', async () => {
    const sellerId = 'seller-1';
    mockPrisma.order.findMany.mockResolvedValue([
      { id: 'order-1', sellerId, sellerAmount: 9000, dispute: null },
    ]);
    mockPrisma.$transaction.mockImplementation(async (cb) => {
      const tx = {
        order: { update: jest.fn().mockResolvedValue({}) },
        wallet: {
          findUnique: jest.fn().mockResolvedValue({ userId: sellerId }),
          update: jest.fn().mockResolvedValue({}),
        },
        transaction: { update: jest.fn().mockResolvedValue({}) },
      };
      return cb(tx);
    });

    await sut.autoReleaseDeliveredOrders();
    expect(mockPrisma.order.findMany).toHaveBeenCalled();
    expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
  });

  it('should skip orders with active disputes', async () => {
    mockPrisma.order.findMany.mockResolvedValue([
      { id: 'order-1', sellerId: 'seller-1', sellerAmount: 9000, dispute: { id: 'dispute-1' } },
    ]);

    await sut.autoReleaseDeliveredOrders();
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });

  it('should do nothing when no eligible orders', async () => {
    mockPrisma.order.findMany.mockResolvedValue([]);
    await sut.autoReleaseDeliveredOrders();
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });
});
