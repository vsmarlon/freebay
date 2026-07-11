import { Injectable } from '@nestjs/common';
import { Dispute, Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import { GetDisputeOutput, GetUserDisputesOutput } from '../../dtos/dispute.dto';
import { DisputeRepository, DisputeWithOrder, CreateDisputeInput } from '../../domain/repositories/dispute.repository';

@Injectable()
export class PrismaDisputeRepository implements DisputeRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: CreateDisputeInput): RepositoryResponse<Dispute> {
    try {
      const dispute = await this.prisma.dispute.create({
        data: {
          order: { connect: { id: data.orderId } },
          openedBy: { connect: { id: data.openedById } },
          reason: data.reason,
          status: 'OPEN',
          expiresAt: data.expiresAt,
        },
      });
      return right(dispute);
    } catch {
      return left(new DatabaseError('Failed to create dispute'));
    }
  }

  async findById(id: string): RepositoryResponse<DisputeWithOrder | null> {
    try {
      return right(
        await this.prisma.dispute.findUnique({
          where: { id },
          include: { order: true },
        }),
      );
    } catch {
      return left(new DatabaseError('Failed to find dispute'));
    }
  }

  async findByIdWithDetails(id: string): RepositoryResponse<GetDisputeOutput | null> {
    try {
      return right(
        await this.prisma.dispute.findUnique({
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
        }),
      );
    } catch {
      return left(new DatabaseError('Failed to find dispute details'));
    }
  }

  async findByUserId(userId: string): RepositoryResponse<GetUserDisputesOutput> {
    try {
      return right(
        await this.prisma.dispute.findMany({
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
        }),
      );
    } catch {
      return left(new DatabaseError('Failed to find user disputes'));
    }
  }

  async update(id: string, data: Prisma.DisputeUpdateInput): RepositoryResponse<Dispute> {
    try {
      return right(await this.prisma.dispute.update({ where: { id }, data }));
    } catch {
      return left(new DatabaseError('Failed to update dispute'));
    }
  }
}
