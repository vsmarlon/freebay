import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, InvalidOrderStateError, UnauthorizedError, BadRequestError } from '@/shared/core/errors';
import { PrismaOrderRepository } from '../repositories/order.repository';
import { PrismaClient, OrderStatus, EscrowStatus } from '@prisma/client';
import { CreateOrderInput, CreateOrderOutput, ConfirmDeliveryInput } from '../dtos/order.dto';

export type { CreateOrderInput, CreateOrderOutput, ConfirmDeliveryInput };

@Injectable()
export class CreateOrderUseCase {
  constructor(
    private orderRepository: PrismaOrderRepository,
    private prisma: PrismaClient,
  ) {}

  async execute(input: CreateOrderInput): Promise<Either<AppError, CreateOrderOutput>> {
    const product = await this.prisma.product.findUnique({ where: { id: input.productId } });
    if (!product) {
      return left(new NotFoundError('Product'));
    }

    if (product.status === 'SOLD') {
      return left(new InvalidOrderStateError('Product already sold', product.status));
    }

    if (product.status === 'PAUSED') {
      return left(new InvalidOrderStateError('Product is reserved for another checkout', product.status));
    }

    if (product.sellerId === input.buyerId) {
      return left(new BadRequestError('Cannot buy your own product'));
    }

    const platformFee = Math.round(input.amount * (input.platformFeePercent / 100));
    const sellerAmount = input.amount - platformFee;

    const order = await this.prisma.$transaction(async (tx) => {
      const reserveResult = await tx.product.updateMany({
        where: {
          id: input.productId,
          status: 'ACTIVE',
        },
        data: {
          status: 'PAUSED',
        },
      });

      if (reserveResult.count === 0) {
        throw new InvalidOrderStateError('Product is unavailable for checkout', product.status);
      }

      return tx.order.create({
        data: {
          buyer: { connect: { id: input.buyerId } },
          seller: { connect: { id: input.sellerId } },
          product: { connect: { id: input.productId } },
          amount: input.amount,
          platformFee,
          sellerAmount,
          status: 'PENDING',
          escrowStatus: 'HELD',
        },
      });
    });

    return right({
      id: order.id,
      buyerId: order.buyerId!,
      sellerId: order.sellerId!,
      productId: order.productId!,
      amount: order.amount,
      status: order.status,
      createdAt: order.createdAt,
    });
  }
}

@Injectable()
export class ConfirmDeliveryUseCase {
  constructor(
    private orderRepository: PrismaOrderRepository,
    private prisma: PrismaClient,
  ) {}

  async execute(input: ConfirmDeliveryInput): Promise<Either<AppError, { confirmed: boolean; sellerAmount: number }>> {
    const order = await this.orderRepository.findById(input.orderId);

    if (!order) {
      return left(new NotFoundError('Order'));
    }

    if (order.buyerId !== input.buyerId) {
      return left(new UnauthorizedError('Only buyer can confirm delivery'));
    }

    if (order.status !== OrderStatus.CONFIRMED && order.status !== OrderStatus.DELIVERED) {
      return left(new InvalidOrderStateError('Order must be CONFIRMED or DELIVERED', order.status));
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.order.update({
        where: { id: input.orderId },
        data: { 
          status: OrderStatus.COMPLETED,
          escrowStatus: EscrowStatus.RELEASED,
          deliveryConfirmedAt: new Date(),
        },
      });

      const wallet = await tx.wallet.findUnique({ where: { userId: order.sellerId } });
      if (wallet) {
        await tx.wallet.update({
          where: { userId: order.sellerId },
          data: {
            pendingBalance: { decrement: order.sellerAmount },
            availableBalance: { increment: order.sellerAmount },
            totalEarned: { increment: order.sellerAmount },
          },
        });
      }

      await tx.transaction.update({
        where: { orderId: input.orderId },
        data: { status: 'RELEASED', releasedAt: new Date() },
      });
    });

    return right({ confirmed: true, sellerAmount: order.sellerAmount });
  }
}

@Injectable()
export class ActivateEscrowUseCase {
  constructor(
    private orderRepository: PrismaOrderRepository,
    private prisma: PrismaClient,
  ) {}

  async execute(orderId: string): Promise<Either<AppError, { activated: boolean }>> {
    const order = await this.orderRepository.findById(orderId);
    if (!order) {
      return left(new NotFoundError('Order'));
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.order.update({
        where: { id: orderId },
        data: { 
          status: OrderStatus.CONFIRMED,
          escrowStatus: EscrowStatus.HELD,
        },
      });

      const wallet = await tx.wallet.findUnique({ where: { userId: order.sellerId } });
      if (wallet) {
        await tx.wallet.update({
          where: { userId: order.sellerId },
          data: { pendingBalance: { increment: order.sellerAmount } },
        });
      }
    });

    return right({ activated: true });
  }
}
