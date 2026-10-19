import { Test } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PaymentGroupDatabaseRepository } from '@/modules/payments/data/repositories/payment-group-database.repository';
import { CartDatabaseRepository } from '../data/repositories/cart-database.repository';
import { CheckoutCartReservation } from './checkout-cart/checkout-cart-reservation';

describe('CheckoutCartReservation buyer serialization', () => {
  it('locks the buyer row and checks for an existing attempt before reserving', async () => {
    const tx = { $queryRaw: jest.fn().mockResolvedValue([{ id: 'buyer-1' }]) };
    const reserveAndCreateOrder = jest.fn().mockResolvedValue({ id: 'order-1' });
    const create = jest.fn().mockResolvedValue({ id: 'group-1' });
    const findPendingForBuyer = jest.fn().mockResolvedValue(right(null));
    const transaction = jest.fn(async (work: (client: typeof tx) => Promise<unknown>) => work(tx));
    const module = await Test.createTestingModule({
      providers: [
        CheckoutCartReservation,
        { provide: PrismaService, useValue: { $transaction: transaction } },
        { provide: CartDatabaseRepository, useValue: { reserveAndCreateOrder } },
        { provide: PaymentGroupDatabaseRepository, useValue: { create, findPendingForBuyer } },
      ],
    }).compile();
    const reservation = module.get(CheckoutCartReservation);

    await reservation.reserve('buyer-1', 'cart:key', 10000, [{
      userId: 'buyer-1', sellerId: 'seller-1', productId: 'product-1', quantity: 1,
      amount: 10000, platformFee: 1000, sellerAmount: 9000, productTitle: 'Product',
    }]);

    expect(tx.$queryRaw).toHaveBeenCalled();
    expect(findPendingForBuyer).toHaveBeenCalledWith('buyer-1', tx);
    expect(tx.$queryRaw.mock.invocationCallOrder[0]).toBeLessThan(
      findPendingForBuyer.mock.invocationCallOrder[0],
    );
    expect(reserveAndCreateOrder).toHaveBeenCalledTimes(1);
  });
});
