import { Test, TestingModule } from '@nestjs/testing';
import { DisputeStatus } from '@prisma/client';
import { left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { DisputeDatabaseRepository } from '../data/repositories/dispute-database.repository';
import { GetDisputeOutput } from '../dtos/dispute.dto';
import { ListAdminDisputesUseCase } from './list-admin-disputes.usecase';

const mockDisputes = {
  findAdminQueue: jest.fn(),
};

const dispute = { id: 'dispute-1', status: DisputeStatus.ESCALATED } as GetDisputeOutput;

describe('ListAdminDisputesUseCase', () => {
  let sut: ListAdminDisputesUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ListAdminDisputesUseCase,
        { provide: DisputeDatabaseRepository, useValue: mockDisputes },
      ],
    }).compile();

    sut = module.get<ListAdminDisputesUseCase>(ListAdminDisputesUseCase);
    jest.clearAllMocks();
  });

  it('returns an empty list and asks for the default limit when the queue is empty', async () => {
    mockDisputes.findAdminQueue.mockResolvedValue(right([]));

    const result = await sut.execute({});

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toEqual({ disputes: [] });
    expect(mockDisputes.findAdminQueue).toHaveBeenCalledWith(undefined, 100);
  });

  it('returns the dispute rows from the repository unchanged', async () => {
    mockDisputes.findAdminQueue.mockResolvedValue(right([dispute]));

    const result = await sut.execute({});

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toEqual({ disputes: [dispute] });
  });

  it('passes the status filter through to the repository', async () => {
    mockDisputes.findAdminQueue.mockResolvedValue(right([dispute]));

    await sut.execute({ status: DisputeStatus.ESCALATED });

    expect(mockDisputes.findAdminQueue).toHaveBeenCalledWith(DisputeStatus.ESCALATED, 100);
  });

  it('passes an explicit limit through to the repository', async () => {
    mockDisputes.findAdminQueue.mockResolvedValue(right([]));

    await sut.execute({ limit: 25 });

    expect(mockDisputes.findAdminQueue).toHaveBeenCalledWith(undefined, 25);
  });

  it('returns the repository error unchanged when the queue query fails', async () => {
    const error = new DatabaseError('queue unavailable');
    mockDisputes.findAdminQueue.mockResolvedValue(left(error));

    const result = await sut.execute({});

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBe(error);
  });
});
