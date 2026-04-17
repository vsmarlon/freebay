import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PrismaOrderRepository } from '../../orders/repositories/order.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { AbacatePayProvider } from '../providers/abacatepay.provider';
import {
  CreatePixPaymentInput,
  CreatePixPaymentOutput,
  ProcessWebhookInput,
} from '../dtos/payment.dto';

@Injectable()
export class CreatePixPaymentUseCase {
  private readonly logger = new Logger(CreatePixPaymentUseCase.name);

  constructor(
    private orderRepository: PrismaOrderRepository,
    private prisma: PrismaService,
    private abacatePay: AbacatePayProvider,
  ) {}

  async execute(input: CreatePixPaymentInput): Promise<Either<AppError, CreatePixPaymentOutput>> {
    const order = await this.orderRepository.findById(input.orderId);
    if (!order) {
      return left(new NotFoundError('Order'));
    }

    if (order.buyerId !== input.userId) {
      return left(new BadRequestError('Order does not belong to this user'));
    }

    const idempotencyKey = input.idempotencyKey || `${input.orderId}-pix-${input.userId}`;

    const existingTransaction = await this.prisma.transaction.findFirst({
      where: { idempotencyKey },
    });

    if (existingTransaction?.pixQrCode) {
      return right({
        orderId: input.orderId,
        pixQrCode: existingTransaction.pixQrCode,
        pixImage: '',
        expiresAt: existingTransaction.pixExpiresAt || new Date(),
      });
    }

    const chargeResult = await this.abacatePay.createPixCharge({
      correlationID: idempotencyKey,
      value: order.amount,
      comment: `FreeBay - Order ${input.orderId}`,
      expiresIn: 3600,
      customer: {
        name: input.customerName,
        taxID: input.customerTaxId,
        email: input.customerEmail,
      },
    });

    if (chargeResult.isLeft()) {
      this.logger.error(`PIX charge failed: ${chargeResult.value.message}`);
      return left(chargeResult.value);
    }

    const charge = chargeResult.value;
    const expiresAt = new Date(Date.now() + 3600 * 1000);

    await this.prisma.transaction.upsert({
      where: { orderId: input.orderId },
      create: {
        order: { connect: { id: input.orderId } },
        externalId: charge.id,
        amount: order.amount,
        platformFee: order.platformFee,
        sellerAmount: order.sellerAmount,
        paymentMethod: 'PIX',
        provider: 'WOOVI',
        status: 'PENDING',
        idempotencyKey,
        pixQrCode: charge.pix?.qrCode,
        pixExpiresAt: expiresAt,
      },
      update: {
        externalId: charge.id,
        status: 'PENDING',
        pixQrCode: charge.pix?.qrCode,
        pixExpiresAt: expiresAt,
      },
    });

    return right({
      orderId: input.orderId,
      pixQrCode: charge.pix?.qrCode || '',
      pixImage: charge.pix?.image || '',
      expiresAt,
    });
  }
}

@Injectable()
export class ProcessWebhookUseCase {
  private readonly logger = new Logger(ProcessWebhookUseCase.name);

  constructor(private prisma: PrismaService) {}

  async execute(input: ProcessWebhookInput): Promise<Either<AppError, { processed: boolean }>> {
    const { event, data } = input;

    if (event === 'charge.completed') {
      const webhookData = data as { correlationID?: string };
      const correlationID = webhookData.correlationID;
      if (!correlationID) {
        return right({ processed: false });
      }

      const transaction = await this.prisma.transaction.findFirst({
        where: { idempotencyKey: correlationID },
        include: { order: true },
      });

      if (!transaction) {
        return right({ processed: false });
      }

      await this.prisma.$transaction(async (tx) => {
        await tx.product.update({
          where: { id: transaction.order.productId },
          data: { status: 'SOLD' },
        });

        await tx.transaction.update({
          where: { id: transaction.id },
          data: { status: 'PAID', paidAt: new Date() },
        });

        await tx.order.update({
          where: { id: transaction.orderId },
          data: { status: 'CONFIRMED', escrowStatus: 'HELD' },
        });

        await tx.wallet.upsert({
          where: { userId: transaction.order.sellerId },
          create: {
            user: { connect: { id: transaction.order.sellerId } },
            pendingBalance: transaction.sellerAmount,
          },
          update: { pendingBalance: { increment: transaction.sellerAmount } },
        });
      });

      return right({ processed: true });
    }

    if (event === 'charge.expired') {
      const webhookData = data as { correlationID?: string };
      const correlationID = webhookData.correlationID;
      if (!correlationID) {
        return right({ processed: false });
      }

      const transaction = await this.prisma.transaction.findFirst({
        where: { idempotencyKey: correlationID },
        include: { order: true },
      });

      if (!transaction) {
        return right({ processed: false });
      }

      await this.prisma.$transaction(async (tx) => {
        await tx.transaction.update({
          where: { id: transaction.id },
          data: { status: 'FAILED' },
        });

        await tx.order.update({
          where: { id: transaction.orderId },
          data: { status: 'CANCELLED' },
        });

        await tx.product.updateMany({
          where: {
            id: transaction.order.productId,
            status: 'PAUSED',
          },
          data: { status: 'ACTIVE' },
        });
      });

      return right({ processed: true });
    }

    return right({ processed: false });
  }
}
