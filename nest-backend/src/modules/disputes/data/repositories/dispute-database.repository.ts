import { Injectable } from '@nestjs/common';
import { Dispute, DisputeStatus, Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import { GetDisputeOutput, GetUserDisputesOutput } from '../../dtos/dispute.dto';
import { DisputeWithOrder, CreateDisputeInput } from '../../types/dispute.types';

@Injectable()
export class PrismaDisputeRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async create(data: CreateDisputeInput): RepositoryResponse<Dispute> {
    return repositoryResponse(() => this.prisma.dispute.create({
      data: {
        order: { connect: { id: data.orderId } },
        openedBy: { connect: { id: data.openedById } },
        reason: data.reason,
        status: DisputeStatus.OPEN,
        expiresAt: data.expiresAt,
      },
    }), 'Failed to create dispute');
  }

  async findById(id: string): RepositoryResponse<DisputeWithOrder | null> {
    return repositoryResponse(() => this.prisma.dispute.findUnique({
      where: { id },
      include: { order: true },
    }), 'Failed to find dispute');
  }

  async findByIdWithDetails(id: string): RepositoryResponse<GetDisputeOutput | null> {
    return repositoryResponse(() => this.prisma.dispute.findUnique({
      where: { id },
      include: {
        order: {
          include: {
            buyer: { select: USER_SELECT_MINIMAL },
            seller: { select: USER_SELECT_MINIMAL },
            product: true,
          },
        },
        openedBy: { select: { id: true, displayName: true } },
      },
    }), 'Failed to find dispute details');
  }

  async findByUserId(userId: string): RepositoryResponse<GetUserDisputesOutput> {
    return repositoryResponse(() => this.prisma.dispute.findMany({
      where: {
        order: {
          OR: [{ buyerId: userId }, { sellerId: userId }],
        },
      },
      include: {
        order: {
          include: { product: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    }), 'Failed to find user disputes');
  }

  async update(id: string, data: Prisma.DisputeUpdateInput): RepositoryResponse<Dispute> {
    return repositoryResponse(() => this.prisma.dispute.update({ where: { id }, data }), 'Failed to update dispute');
  }
}
