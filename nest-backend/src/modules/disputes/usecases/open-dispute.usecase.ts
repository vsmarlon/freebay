import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError, UnauthorizedError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { OrderStatus } from '@prisma/client';
import { OpenDisputeInput, OpenDisputeOutput } from '../dtos/dispute.dto';
import { NotificationService } from '../../notifications/services/notification.service';
import { PrismaDisputeRepository } from '../repositories/dispute.repository';

@Injectable()
export class OpenDisputeUseCase {
  constructor(
    private prisma: PrismaService,
    private disputeRepo: PrismaDisputeRepository,
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

    if (order.status !== OrderStatus.CONFIRMED && order.status !== OrderStatus.DELIVERED) {
      return left(new BadRequestError('Order must be CONFIRMED or DELIVERED to open dispute'));
    }

    const currentTime = now ?? new Date();
    const deliveryTime = order.deliveryConfirmedAt || order.createdAt;
    const hoursSinceDelivery = (currentTime.getTime() - deliveryTime.getTime()) / (1000 * 60 * 60);
    if (hoursSinceDelivery > 48) {
      return left(new BadRequestError('Dispute window has expired (48h after delivery)'));
    }

    const expiresAt = new Date(currentTime.getTime() + 72 * 60 * 60 * 1000);

    const dispute = await this.disputeRepo.create({
      orderId: input.orderId,
      openedById: input.userId,
      reason: input.reason,
      expiresAt,
    });

    await this.prisma.order.update({
      where: { id: input.orderId },
      data: { status: OrderStatus.DISPUTED },
    });

    const otherUserId = order.buyerId === input.userId ? order.sellerId : order.buyerId;
    await Promise.all([
      this.notificationService.notifyDispute(otherUserId, dispute.id, 'Uma disputa foi aberta em um dos seus pedidos'),
      this.notificationService.notifyOrderStatus(input.userId, order.id, 'DISPUTED'),
      this.notificationService.notifyOrderStatus(otherUserId, order.id, 'DISPUTED'),
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
