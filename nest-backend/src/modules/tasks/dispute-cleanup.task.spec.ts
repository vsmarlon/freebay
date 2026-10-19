import { Test, TestingModule } from '@nestjs/testing';
import { DisputeCleanupTask } from './dispute-cleanup.task';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { DisputeResolutionExecutionService } from '@/modules/disputes/services/dispute-resolution-execution.service';

const mockPrisma = {
  $transaction: jest.fn(),
  dispute: {
    findMany: jest.fn(),
    update: jest.fn(),
  },
};

const mockResolutionExecution = {
  resolveInFavorOfBuyer: jest.fn(),
  resolveInFavorOfSeller: jest.fn().mockResolvedValue(undefined),
};

describe('DisputeCleanupTask', () => {
  let sut: DisputeCleanupTask;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DisputeCleanupTask,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: DisputeResolutionExecutionService, useValue: mockResolutionExecution },
      ],
    }).compile();

    sut = module.get<DisputeCleanupTask>(DisputeCleanupTask);
    jest.clearAllMocks();
  });

  it('keeps expired disputes held for manual review instead of awarding the seller', async () => {
    const dispute = { id: 'dispute-1', order: { id: 'order-1', sellerId: 'seller-1', sellerAmount: 9000 } };
    mockPrisma.dispute.findMany.mockResolvedValue([dispute]);
    await sut.cleanupExpiredDisputes();

    expect(mockPrisma.dispute.findMany).toHaveBeenCalled();
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    expect(mockResolutionExecution.resolveInFavorOfSeller).not.toHaveBeenCalled();
  });

  it('does nothing when no expired disputes', async () => {
    mockPrisma.dispute.findMany.mockResolvedValue([]);
    await sut.cleanupExpiredDisputes();
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    expect(mockResolutionExecution.resolveInFavorOfSeller).not.toHaveBeenCalled();
  });
});
