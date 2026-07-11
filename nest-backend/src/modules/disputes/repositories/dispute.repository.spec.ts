import { Test, TestingModule } from '@nestjs/testing';
import { PrismaDisputeRepository } from '../data/repositories/dispute-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

describe('PrismaDisputeRepository', () => {
  let sut: PrismaDisputeRepository;

  const mockPrisma = {
    dispute: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [PrismaDisputeRepository, { provide: PrismaService, useValue: mockPrisma }],
    }).compile();

    sut = module.get<PrismaDisputeRepository>(PrismaDisputeRepository);
    jest.clearAllMocks();
  });

  it('create connects the order and opener and defaults to OPEN', async () => {
    const expiresAt = new Date();
    mockPrisma.dispute.create.mockResolvedValue({ id: 'dispute-1' });

    await sut.create({ orderId: 'order-1', openedById: 'buyer-1', reason: 'Test', expiresAt });

    expect(mockPrisma.dispute.create).toHaveBeenCalledWith({
      data: {
        order: { connect: { id: 'order-1' } },
        openedBy: { connect: { id: 'buyer-1' } },
        reason: 'Test',
        status: 'OPEN',
        expiresAt,
      },
    });
  });

  it('findById includes the order relation', async () => {
    mockPrisma.dispute.findUnique.mockResolvedValue({ id: 'dispute-1', order: { id: 'order-1' } });

    await sut.findById('dispute-1');

    expect(mockPrisma.dispute.findUnique).toHaveBeenCalledWith({
      where: { id: 'dispute-1' },
      include: { order: true },
    });
  });

  it('findByIdWithDetails includes buyer/seller/product/openedBy', async () => {
    mockPrisma.dispute.findUnique.mockResolvedValue({ id: 'dispute-1' });

    await sut.findByIdWithDetails('dispute-1');

    expect(mockPrisma.dispute.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'dispute-1' } }),
    );
  });

  it('findByUserId filters by buyer or seller and orders by createdAt desc', async () => {
    mockPrisma.dispute.findMany.mockResolvedValue([]);

    await sut.findByUserId('user-1');

    expect(mockPrisma.dispute.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { order: { OR: [{ buyerId: 'user-1' }, { sellerId: 'user-1' }] } },
        orderBy: { createdAt: 'desc' },
      }),
    );
  });

  it('update delegates to prisma.dispute.update', async () => {
    mockPrisma.dispute.update.mockResolvedValue({ id: 'dispute-1', status: 'AWAITING_SELLER' });

    await sut.update('dispute-1', { status: 'AWAITING_SELLER' });

    expect(mockPrisma.dispute.update).toHaveBeenCalledWith({
      where: { id: 'dispute-1' },
      data: { status: 'AWAITING_SELLER' },
    });
  });
});
