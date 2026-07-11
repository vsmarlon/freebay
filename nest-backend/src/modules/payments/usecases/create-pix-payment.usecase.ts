import { Injectable, Logger } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError } from '@/shared/core/errors';
import { PrismaOrderRepository } from '../../orders/repositories/order.repository';
import { UserRepository } from '../../auth/domain/repositories/user.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { AbacatePayProvider } from '../providers/abacatepay.provider';
import { CreatePixPaymentInput, CreatePixPaymentOutput } from '../dtos/payment.dto';

@Injectable()
export class CreatePixPaymentUseCase {
  private readonly logger = new Logger(CreatePixPaymentUseCase.name);

  constructor(
    private orderRepository: PrismaOrderRepository,
    private userRepository: UserRepository,
    private prisma: PrismaService,
    private abacatePay: AbacatePayProvider,
  ) {}

  async execute(input: CreatePixPaymentInput): Promise<Either<AppError, CreatePixPaymentOutput>> {
    const orderResult = await this.orderRepository.findById(input.orderId);
    if (isLeft(orderResult)) return left(orderResult.value);
    if (!orderResult.value) return left(new NotFoundError('Order'));

    const order = orderResult.value;
    if (order.buyerId !== input.userId) {
      return left(new BadRequestError('Order does not belong to this user'));
    }

    const needsUserFetch = !input.customerName || !input.customerEmail || !input.customerTaxId;
    const userResult = needsUserFetch
      ? await this.userRepository.findPaymentInfo(input.userId)
      : right(null);
    if (isLeft(userResult)) return left(userResult.value);

    const user = userResult.value;
    const customerName  = input.customerName  ?? user?.displayName ?? '';
    const customerEmail = input.customerEmail ?? user?.email ?? '';
    const customerTaxId = input.customerTaxId ?? user?.cpf;

    if (!customerTaxId) {
      return left(new BadRequestError('Adicione seu CPF no perfil antes de realizar uma compra'));
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
        name: customerName,
        taxID: customerTaxId,
        email: customerEmail,
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
