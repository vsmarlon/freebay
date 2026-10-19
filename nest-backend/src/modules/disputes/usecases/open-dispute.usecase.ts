import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError, UnauthorizedError, DatabaseError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { Dispute, OrderStatus } from '@prisma/client';
import {
  DISPUTE_EXPIRY_WINDOW_HOURS,
  DISPUTE_HOUR_IN_MILLISECONDS,
  DISPUTE_OPENING_WINDOW_HOURS,
} from '../dispute.constants';
import { OpenDisputeInput, OpenDisputeOutput } from '../dtos/dispute.dto';
import { NotificationService } from '../../notifications/services/notification.service';
import { DisputeDatabaseRepository } from '../data/repositories/dispute-database.repository';

const DISPUTE_ORDER_CLAIM_LOST = 'DISPUTE_ORDER_CLAIM_LOST';
const DISPUTE_CREATE_FAILED = 'DISPUTE_CREATE_FAILED';

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

    if (order.dispute) {
      return left(new BadRequestError('Dispute already exists for this order'));
    }

    if (order.status !== OrderStatus.CONFIRMED &&
        order.status !== OrderStatus.SHIPPED &&
        order.status !== OrderStatus.DELIVERED) {
      return left(new BadRequestError('Order must be CONFIRMED, SHIPPED or DELIVERED to open dispute'));
    }

    const currentTime = now ?? new Date();
    if (order.status !== OrderStatus.SHIPPED) {
      const deliveryTime = order.deliveryConfirmedAt || order.createdAt;
      const hoursSinceDelivery =
        (currentTime.getTime() - deliveryTime.getTime()) / DISPUTE_HOUR_IN_MILLISECONDS;
      if (hoursSinceDelivery > DISPUTE_OPENING_WINDOW_HOURS) {
        return left(new BadRequestError(`Dispute window has expired (${DISPUTE_OPENING_WINDOW_HOURS}h after delivery)`));
      }
    }

    const expiresAt = new Date(
      currentTime.getTime() + DISPUTE_EXPIRY_WINDOW_HOURS * DISPUTE_HOUR_IN_MILLISECONDS,
    );

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
          data: { status: OrderStatus.DISPUTED },
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

    const otherUserId = order.buyerId === input.userId ? order.sellerId : order.buyerId;
    await Promise.all([
      this.notificationService.notifyDispute(otherUserId, dispute.id, order.id, 'Uma disputa foi aberta em um dos seus pedidos'),
      this.notificationService.notifyOrderStatus(input.userId, order.id, OrderStatus.DISPUTED),
      this.notificationService.notifyOrderStatus(otherUserId, order.id, OrderStatus.DISPUTED),
    ]);

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
