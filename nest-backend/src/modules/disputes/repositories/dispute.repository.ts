import { Injectable } from '@nestjs/common';
import { Dispute, Order, Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import { GetDisputeOutput, GetUserDisputesOutput } from '../dtos/dispute.dto';
import { Either, left, right } from '@/shared/core/either';
import { AppError, DatabaseError } from '@/shared/core/errors';

export type DisputeWithOrder = Dispute & { order: Order };

@Injectable()
export class PrismaDisputeRepository {
  constructor(private prisma: PrismaService) {}

  async create(data: {
    orderId: string;
    openedById: string;
    reason: string;
    expiresAt: Date;
  }): Promise<Either<AppError, Dispute>> {
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

  async findById(id: string): Promise<DisputeWithOrder | null> {
    return this.prisma.dispute.findUnique({
      where: { id },
      include: { order: true },
    });
  }

  async findByIdWithDetails(id: string): Promise<GetDisputeOutput | null> {
    return this.prisma.dispute.findUnique({
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
    });
  }

  async findByUserId(userId: string): Promise<GetUserDisputesOutput> {
    return this.prisma.dispute.findMany({
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
    });
  }

  async update(id: string, data: Prisma.DisputeUpdateInput): Promise<Dispute> {
    return this.prisma.dispute.update({
      where: { id },
      data,
    });
  }
}
