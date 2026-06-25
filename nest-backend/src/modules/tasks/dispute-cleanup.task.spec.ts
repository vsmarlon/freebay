import { Test, TestingModule } from '@nestjs/testing';
import { DisputeCleanupTask } from './dispute-cleanup.task';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

const mockPrisma = {
  order: { update: jest.fn() },
  wallet: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  $transaction: jest.fn(),
  dispute: {
    findMany: jest.fn(),
    update: jest.fn(),
  },
};

describe('DisputeCleanupTask', () => {
  let sut: DisputeCleanupTask;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DisputeCleanupTask,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<DisputeCleanupTask>(DisputeCleanupTask);
    jest.clearAllMocks();
  });

  it('should auto-resolve expired disputes in favor of seller', async () => {
    mockPrisma.dispute.findMany.mockResolvedValue([
      { id: 'dispute-1', order: { id: 'order-1', sellerId: 'seller-1', sellerAmount: 9000 } },
    ]);
    mockPrisma.$transaction.mockImplementation(async (cb) => {
      const tx = {
        dispute: { update: jest.fn().mockResolvedValue({}) },
        order: { update: jest.fn().mockResolvedValue({}) },
        wallet: {
          findUnique: jest.fn().mockResolvedValue({ userId: 'seller-1' }),
          update: jest.fn().mockResolvedValue({}),
        },
      };
      return cb(tx);
    });

    await sut.cleanupExpiredDisputes();
    expect(mockPrisma.dispute.findMany).toHaveBeenCalled();
    expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
  });

  it('should do nothing when no expired disputes', async () => {
    mockPrisma.dispute.findMany.mockResolvedValue([]);
    await sut.cleanupExpiredDisputes();
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });
});
