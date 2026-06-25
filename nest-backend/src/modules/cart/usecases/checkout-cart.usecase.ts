import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaCartRepository } from '../repositories/cart.repository';
import {
  CheckoutCartInput,
  CheckoutCartItemOutput,
  CheckoutCartOutput,
} from '../dtos/cart.dto';
import { CreatePixPaymentUseCase } from '@/modules/payments/usecases/payment.usecase';

@Injectable()
export class CheckoutCartUseCase {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cartRepository: PrismaCartRepository,
    private readonly createPixPaymentUseCase: CreatePixPaymentUseCase,
  ) {}

  async execute(
    input: CheckoutCartInput,
  ): Promise<Either<AppError, CheckoutCartOutput>> {
    const user = await this.prisma.user.findUnique({
      where: { id: input.userId },
      select: { displayName: true, email: true, cpf: true },
    });

    if (!user?.cpf) {
      return left(new BadRequestError('Adicione seu CPF no perfil antes de realizar uma compra'));
    }

    const cartItems = await this.cartRepository.getUserCart(input.userId);

    if (cartItems.length === 0) {
      return left(new BadRequestError('Cart is empty'));
    }

    const checkoutItems: CheckoutCartItemOutput[] = [];

    for (const item of cartItems) {
      if (item.product.sellerId === input.userId) {
        return left(new BadRequestError('Cannot buy your own product'));
      }

      if (item.product.status !== 'ACTIVE') {
        return left(new BadRequestError('One or more cart products are unavailable'));
      }

      const amount = item.product.price * item.quantity;
      const platformFee = Math.round(amount * 0.1);
      const sellerAmount = amount - platformFee;

      const order = await this.prisma.$transaction(async (tx) => {
        const reserveResult = await tx.product.updateMany({
          where: {
            id: item.productId,
            status: 'ACTIVE',
          },
          data: {
            status: 'PAUSED',
          },
        });

        if (reserveResult.count === 0) {
          throw new BadRequestError('One or more cart products are unavailable');
        }

        return tx.order.create({
          data: {
            buyer: { connect: { id: input.userId } },
            seller: { connect: { id: item.product.sellerId } },
            product: { connect: { id: item.productId } },
            amount,
            platformFee,
            sellerAmount,
            status: 'PENDING',
            escrowStatus: 'HELD',
          },
        });
      });

      const pixResult = await this.createPixPaymentUseCase.execute({
        orderId: order.id,
        userId: input.userId,
        customerName: user.displayName,
        customerTaxId: user.cpf,
        customerEmail: user.email,
        idempotencyKey: `cart-${input.userId}-${order.id}`,
      });

      if (pixResult.isLeft()) {
        await this.prisma.$transaction(async (tx) => {
          await tx.order.delete({
            where: { id: order.id },
          });

          await tx.product.updateMany({
            where: {
              id: item.productId,
              status: 'PAUSED',
            },
            data: { status: 'ACTIVE' },
          });
        });

        return left(pixResult.value);
      }

      checkoutItems.push({
        orderId: order.id,
        productId: item.productId,
        productTitle: item.product.title,
        quantity: item.quantity,
        amount,
        pixQrCode: pixResult.value.pixQrCode,
        pixImage: pixResult.value.pixImage,
        expiresAt: pixResult.value.expiresAt,
      });
    }

    await this.cartRepository.clear(input.userId);

    return right({
      items: checkoutItems,
      totalOrders: checkoutItems.length,
      totalAmount: checkoutItems.reduce((sum, item) => sum + item.amount, 0),
    });
  }
}
