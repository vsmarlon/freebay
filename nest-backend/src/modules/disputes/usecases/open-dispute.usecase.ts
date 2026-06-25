import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError, UnauthorizedError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { OrderStatus } from '@prisma/client';
import { OpenDisputeInput, OpenDisputeOutput } from '../dtos/dispute.dto';
import { NotificationService } from '../../notifications/services/notification.service';

@Injectable()
export class OpenDisputeUseCase {
  constructor(
    private prisma: PrismaService,
    private notificationService: NotificationService,
  ) {}

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

    const otherUserId = order.buyerId === input.userId ? order.sellerId : order.buyerId;
    await this.notificationService.notifyDispute(otherUserId, dispute.id, 'Uma disputa foi aberta em um dos seus pedidos');
    await this.notificationService.notifyOrderStatus(input.userId, order.id, 'DISPUTED');
    await this.notificationService.notifyOrderStatus(otherUserId, order.id, 'DISPUTED');

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
