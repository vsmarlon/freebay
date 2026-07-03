import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError } from '@/shared/core/errors';
import { CartRepository } from '../domain/repositories/cart.repository';
import { CreatePixPaymentUseCase } from '@/modules/payments/usecases/payment.usecase';

export interface CheckoutCartInput {
  userId: string;
}

export interface CheckoutCartItemOutput {
  orderId: string;
  productId: string;
  productTitle: string;
  quantity: number;
  amount: number;
  pixQrCode: string;
  pixImage: string;
  expiresAt: Date;
}

export interface CheckoutCartOutput {
  items: CheckoutCartItemOutput[];
  totalOrders: number;
  totalAmount: number;
}

@Injectable()
export class CheckoutCartUseCase {
  constructor(
    private readonly cartRepository: CartRepository,
    private readonly createPixPaymentUseCase: CreatePixPaymentUseCase,
  ) {}

  async execute(input: CheckoutCartInput): Promise<Either<AppError, CheckoutCartOutput>> {
    const cpfResult = await this.cartRepository.findUserCpf(input.userId);
    if (isLeft(cpfResult)) return left(cpfResult.value);
    if (!cpfResult.value) {
      return left(new BadRequestError('Adicione seu CPF no perfil antes de realizar uma compra'));
    }

    const cartResult = await this.cartRepository.getUserCart(input.userId);
    if (isLeft(cartResult)) return left(cartResult.value);

    const cartItems = cartResult.value;
    if (cartItems.length === 0) {
      return left(new BadRequestError('Carrinho vazio'));
    }

    const checkoutItems: CheckoutCartItemOutput[] = [];

    for (const item of cartItems) {
      if (item.product.sellerId === input.userId) {
        return left(new BadRequestError('Você não pode comprar seu próprio produto'));
      }
      if (item.product.status !== 'ACTIVE') {
        return left(new BadRequestError('Um ou mais produtos do carrinho não estão disponíveis'));
      }

      if (item.product.quantity > 1) {
        const availableStock = item.product.quantity - item.product.soldCount;
        if (availableStock < item.quantity) {
          return left(new BadRequestError(`Estoque insuficiente para ${item.product.title}`));
        }
      }

      const amount = item.product.price * item.quantity;
      const platformFee = Math.round(amount * 0.1);
      const sellerAmount = amount - platformFee;

      const orderResult = await this.cartRepository.createOrderFromCheckout({
        userId: input.userId,
        sellerId: item.product.sellerId,
        productId: item.productId,
        amount,
        platformFee,
        sellerAmount,
      });
      if (isLeft(orderResult)) return left(orderResult.value);

      const pixResult = await this.createPixPaymentUseCase.execute({
        orderId: orderResult.value.id,
        userId: input.userId,
        idempotencyKey: `cart-${input.userId}-${orderResult.value.id}`,
      });

      if (isLeft(pixResult)) {
        await this.cartRepository.rollbackOrderReservation(orderResult.value.id, item.productId);
        return left(pixResult.value);
      }

      checkoutItems.push({
        orderId: orderResult.value.id,
        productId: item.productId,
        productTitle: item.product.title,
        quantity: item.quantity,
        amount,
        pixQrCode: pixResult.value.pixQrCode,
        pixImage: pixResult.value.pixImage,
        expiresAt: pixResult.value.expiresAt,
      });
    }

    const clearResult = await this.cartRepository.clear(input.userId);
    if (isLeft(clearResult)) return left(clearResult.value);

    return right({
      items: checkoutItems,
      totalOrders: checkoutItems.length,
      totalAmount: checkoutItems.reduce((sum, item) => sum + item.amount, 0),
    });
  }
}
