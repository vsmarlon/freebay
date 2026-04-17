import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError, UnauthorizedError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { OrderStatus, Prisma } from '@prisma/client';
import { OpenDisputeInput, OpenDisputeOutput, GetDisputeOutput, GetUserDisputesOutput } from '../dtos/dispute.dto';

@Injectable()
export class OpenDisputeUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: OpenDisputeInput): Promise<Either<AppError, OpenDisputeOutput>> {
    const order = await this.prisma.order.findUnique({
      where: { id: input.orderId },
      include: { dispute: true },
    });

    if (!order) {
      return left(new NotFoundError('Order'));
    }

    if (order.buyerId !== input.userId && order.sellerId !== input.userId) {
      return left(new UnauthorizedError('Not authorized to open dispute for this order'));
    }

    if (order.dispute) {
      return left(new BadRequestError('Dispute already exists for this order'));
    }

    if (order.status !== OrderStatus.CONFIRMED && order.status !== OrderStatus.DELIVERED) {
      return left(new BadRequestError('Order must be CONFIRMED or DELIVERED to open dispute'));
    }

    const deliveryTime = order.deliveryConfirmedAt || order.createdAt;
    const hoursSinceDelivery = (Date.now() - deliveryTime.getTime()) / (1000 * 60 * 60);
    if (hoursSinceDelivery > 48) {
      return left(new BadRequestError('Dispute window has expired (48h after delivery)'));
    }

    const expiresAt = new Date();
    expiresAt.setHours(expiresAt.getHours() + 72);

    const dispute = await this.prisma.dispute.create({
      data: {
        order: { connect: { id: input.orderId } },
        openedBy: { connect: { id: input.userId } },
        reason: input.reason,
        status: 'OPEN',
        expiresAt,
      },
    });

    await this.prisma.order.update({
      where: { id: input.orderId },
      data: { status: OrderStatus.DISPUTED },
    });

    return right({
      id: dispute.id,
      orderId: dispute.orderId,
      openedById: dispute.openedById,
      reason: dispute.reason,
      status: dispute.status,
      createdAt: dispute.createdAt,
      expiresAt: dispute.expiresAt,
    });
  }
}

@Injectable()
export class GetDisputeUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(disputeId: string, userId: string): Promise<Either<AppError, GetDisputeOutput>> {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
      include: {
        order: {
          include: {
            buyer: { select: { id: true, displayName: true, avatarUrl: true } },
            seller: { select: { id: true, displayName: true, avatarUrl: true } },
            product: true,
          },
        },
        openedBy: { select: { id: true, displayName: true } },
      },
    });

    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    const isParticipant = dispute.order.buyerId === userId || dispute.order.sellerId === userId;
    if (!isParticipant) {
      return left(new UnauthorizedError('Not authorized to view this dispute'));
    }

    return right(dispute);
  }
}

@Injectable()
export class GetUserDisputesUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(userId: string): Promise<Either<AppError, GetUserDisputesOutput>> {
    const disputes = await this.prisma.dispute.findMany({
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

    return right(disputes);
  }
}

@Injectable()
export class SubmitEvidenceUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: { disputeId: string; userId: string; evidence: Prisma.InputJsonValue }): Promise<Either<AppError, { submitted: boolean }>> {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: input.disputeId },
      include: { order: true },
    });

    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    const isBuyer = dispute.order.buyerId === input.userId;
    const isSeller = dispute.order.sellerId === input.userId;
    if (!isBuyer && !isSeller) {
      return left(new UnauthorizedError('Not authorized'));
    }

    const updateData = isBuyer
      ? { buyerEvidence: input.evidence, status: 'AWAITING_SELLER' as const }
      : { sellerEvidence: input.evidence, status: 'AWAITING_BUYER' as const };

    await this.prisma.dispute.update({
      where: { id: input.disputeId },
      data: updateData,
    });

    return right({ submitted: true });
  }
}

@Injectable()
export class ResolveDisputeUseCase {
  constructor(private prisma: PrismaService) {}

  async execute(input: { disputeId: string; resolution: string; winner: 'BUYER' | 'SELLER' }): Promise<Either<AppError, { resolved: boolean }>> {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: input.disputeId },
      include: { order: true },
    });

    if (!dispute) {
      return left(new NotFoundError('Dispute'));
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.dispute.update({
        where: { id: input.disputeId },
        data: {
          resolution: input.resolution,
          status: 'RESOLVED',
          resolvedAt: new Date(),
        },
      });

      if (input.winner === 'BUYER') {
        await tx.order.update({
          where: { id: dispute.orderId },
          data: { status: OrderStatus.CANCELLED, escrowStatus: 'REFUNDED' },
        });

        const buyerWallet = await tx.wallet.findUnique({ where: { userId: dispute.order.buyerId } });
        if (buyerWallet) {
          await tx.wallet.update({
            where: { userId: dispute.order.buyerId },
            data: { availableBalance: { increment: dispute.order.amount } },
          });
        }
      } else {
        await tx.order.update({
          where: { id: dispute.orderId },
          data: { status: OrderStatus.COMPLETED, escrowStatus: 'RELEASED' },
        });

        const sellerWallet = await tx.wallet.findUnique({ where: { userId: dispute.order.sellerId } });
        if (sellerWallet) {
          await tx.wallet.update({
            where: { userId: dispute.order.sellerId },
            data: {
              pendingBalance: { decrement: dispute.order.sellerAmount },
              availableBalance: { increment: dispute.order.sellerAmount },
              totalEarned: { increment: dispute.order.sellerAmount },
            },
          });
        }
      }
    });

    return right({ resolved: true });
  }
}
