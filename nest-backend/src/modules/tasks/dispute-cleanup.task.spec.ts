import { Test, TestingModule } from '@nestjs/testing';
import { DisputeCleanupTask } from './dispute-cleanup.task';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

const mockPrisma = {
  dispute: {
    updateMany: jest.fn(),
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

  it('escalates every expired non-escalated dispute in one guarded update', async () => {
    const now = new Date('2026-11-09T12:00:00.000Z');
    mockPrisma.dispute.updateMany.mockResolvedValue({ count: 2 });

    await sut.cleanupExpiredDisputes(now);

    expect(mockPrisma.dispute.updateMany).toHaveBeenCalledWith({
      where: {
        status: { in: ['OPEN', 'AWAITING_SELLER', 'AWAITING_BUYER'] },
        expiresAt: { lt: now },
      },
      data: { status: 'ESCALATED' },
    });
  });

  it('does nothing when no dispute is expired', async () => {
    mockPrisma.dispute.updateMany.mockResolvedValue({ count: 0 });

    await sut.cleanupExpiredDisputes(new Date('2026-11-09T12:00:00.000Z'));

    expect(mockPrisma.dispute.updateMany).toHaveBeenCalledTimes(1);
  });
});
