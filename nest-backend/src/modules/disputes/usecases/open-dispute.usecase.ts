import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError, UnauthorizedError, DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Dispute, DisputeStatus, OrderStatus } from '@prisma/client';
import {
  DISPUTE_ESCALATION_WINDOW_HOURS,
  DISPUTE_HOUR_IN_MILLISECONDS,
  DISPUTE_OPENING_WINDOW_HOURS,
} from '../dispute.constants';
import { OpenDisputeInput, OpenDisputeOutput } from '../dtos/dispute.dto';
import { NotificationService } from '../../notifications/services/notification.service';
import { DisputeDatabaseRepository } from '../data/repositories/dispute-database.repository';

const DISPUTE_ORDER_CLAIM_LOST = 'DISPUTE_ORDER_CLAIM_LOST';
const DISPUTE_CREATE_FAILED = 'DISPUTE_CREATE_FAILED';

const DISPUTABLE_ORDER_STATUSES = [
  OrderStatus.CONFIRMED,
  OrderStatus.SHIPPED,
  OrderStatus.DELIVERED,
] as const;

@Injectable()
export class OpenDisputeUseCase {
  constructor(
    private prisma: PrismaService,
    private disputeRepo: DisputeDatabaseRepository,
    private notificationService: NotificationService,
  ) {}

  async execute(input: OpenDisputeInput, now?: Date): Promise<Either<AppError, OpenDisputeOutput>> {
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

    if (!DISPUTABLE_ORDER_STATUSES.some((status) => status === order.status)) {
      return left(new BadRequestError('Order must be CONFIRMED, SHIPPED or DELIVERED to open dispute'));
    }

    const currentTime = now ?? new Date();
    if (!this.isWithinOpeningWindow(order, currentTime)) {
      return left(new BadRequestError(`Dispute window has expired (${DISPUTE_OPENING_WINDOW_HOURS}h after delivery)`));
    }

    const expiresAt = new Date(
      currentTime.getTime() + DISPUTE_ESCALATION_WINDOW_HOURS * DISPUTE_HOUR_IN_MILLISECONDS,
    );

    if (order.dispute) {
      return this.reopen(order.dispute, input, expiresAt);
    }

    let dispute: Dispute;
    try {
      dispute = await this.prisma.$transaction(async (tx) => {
        const claimed = await tx.order.updateMany({
          where: {
            id: input.orderId,
            status: order.status,
            cancellationReason: null,
            dispute: { is: null },
          },
          data: { status: OrderStatus.DISPUTED, preDisputeStatus: order.status },
        });
        if (claimed.count === 0) throw new Error(DISPUTE_ORDER_CLAIM_LOST);

        const created = await this.disputeRepo.create({
          orderId: input.orderId,
          openedById: input.userId,
          reason: input.reason,
          expiresAt,
        }, tx);
        if (created.isLeft()) throw new Error(DISPUTE_CREATE_FAILED);
        return created.value;
      });
    } catch (error) {
      if (error instanceof Error && error.message === DISPUTE_ORDER_CLAIM_LOST) {
        return left(new BadRequestError('Order changed and can no longer be disputed'));
      }
      return left(new DatabaseError('Failed to open dispute'));
    }

    await this.notify(openedByOther(input.userId, order), dispute, order.id);
    return right(this.toOutput(dispute));
  }

  private async reopen(
    dispute: Dispute,
    input: OpenDisputeInput,
    expiresAt: Date,
  ): Promise<Either<AppError, OpenDisputeOutput>> {
    if (dispute.openedById !== input.userId) {
      return left(new UnauthorizedError('Only the dispute opener may reopen it'));
    }
    if (dispute.status !== DisputeStatus.CANCELLED) {
      return left(new BadRequestError('Dispute already exists for this order'));
    }
    if (input.reason.trim().length === 0) {
      return left(new BadRequestError('Informe um motivo de reabertura válido'));
    }

    try {
      const reopened = await this.disputeRepo.reopen({
        disputeId: dispute.id,
        orderId: dispute.orderId,
        reason: input.reason,
        expiresAt,
      });
      if (!reopened) {
        return left(new BadRequestError('Order changed and can no longer be disputed'));
      }
    } catch {
      return left(new BadRequestError('Order changed and can no longer be disputed'));
    }

    const order = await this.prisma.order.findUnique({
      where: { id: dispute.orderId },
      select: { buyerId: true, sellerId: true },
    });
    if (order) await this.notify(openedByOther(input.userId, order), dispute, dispute.orderId);

    return right(this.toOutput({ ...dispute, status: DisputeStatus.OPEN, expiresAt }));
  }

  private isWithinOpeningWindow(
    order: { status: OrderStatus; deliveryConfirmedAt: Date | null; createdAt: Date },
    now: Date,
  ): boolean {
    if (order.status === OrderStatus.SHIPPED) return true;
    const deliveryTime = order.deliveryConfirmedAt ?? order.createdAt;
    return (now.getTime() - deliveryTime.getTime()) / DISPUTE_HOUR_IN_MILLISECONDS
      <= DISPUTE_OPENING_WINDOW_HOURS;
  }

  private async notify(otherUserId: string, dispute: Dispute, orderId: string): Promise<void> {
    await Promise.all([
      this.notificationService.notifyDispute(otherUserId, dispute.id, orderId, 'Uma disputa foi aberta em um dos seus pedidos'),
      this.notificationService.notifyOrderStatus(dispute.openedById, orderId, OrderStatus.DISPUTED),
      this.notificationService.notifyOrderStatus(otherUserId, orderId, OrderStatus.DISPUTED),
    ]);
  }

  private toOutput(dispute: Dispute): OpenDisputeOutput {
    return {
      id: dispute.id,
      orderId: dispute.orderId,
      openedById: dispute.openedById,
      reason: dispute.reason,
      status: dispute.status,
      createdAt: dispute.createdAt,
      expiresAt: dispute.expiresAt,
    };
  }
}

function openedByOther(
  userId: string,
  order: { buyerId: string; sellerId: string },
): string {
  return order.buyerId === userId ? order.sellerId : order.buyerId;
}
