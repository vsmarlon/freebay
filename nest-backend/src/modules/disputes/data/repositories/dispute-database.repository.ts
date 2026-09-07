import { Injectable } from '@nestjs/common';
import { Dispute, Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import { GetDisputeOutput, GetUserDisputesOutput } from '../../dtos/dispute.dto';
import { DisputeWithOrder, CreateDisputeInput } from '../../types/dispute.types';

@Injectable()
export class PrismaDisputeRepository extends BasePrismaRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: CreateDisputeInput): RepositoryResponse<Dispute> {
    return this.safeRun(() => this.prisma.dispute.create({
      data: {
        order: { connect: { id: data.orderId } },
        openedBy: { connect: { id: data.openedById } },
        reason: data.reason,
        status: 'OPEN',
        expiresAt: data.expiresAt,
      },
    }), 'Failed to create dispute');
  }

  async findById(id: string): RepositoryResponse<DisputeWithOrder | null> {
    return this.safeRun(() => this.prisma.dispute.findUnique({
      where: { id },
      include: { order: true },
    }), 'Failed to find dispute');
  }

  async findByIdWithDetails(id: string): RepositoryResponse<GetDisputeOutput | null> {
    return this.safeRun(() => this.prisma.dispute.findUnique({
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
    return this.safeRun(() => this.prisma.dispute.findMany({
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
    return this.safeRun(() => this.prisma.dispute.update({ where: { id }, data }), 'Failed to update dispute');
  }
}
