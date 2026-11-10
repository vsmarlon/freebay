import { Test } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PaymentGroupDatabaseRepository } from './payment-group-database.repository';

describe('PaymentGroupDatabaseRepository.findLatestOpenForBuyer', () => {
  it('scopes lookup to the authenticated buyer and preserves existing identifiers', async () => {
    const findFirst = jest.fn().mockResolvedValue({
      id: 'group-1', buyerId: 'buyer-1', amount: 12500, currency: 'usd', status: 'PENDING',
      idempotencyKey: 'cart:buyer-1:intent:hash', stripePaymentIntentId: 'pi_1',
      stripeSessionId: null, clientSecret: 'pi_1_secret', checkoutUrl: null,
      expiresAt: new Date('2026-10-10T00:00:00.000Z'),
      transactions: [{
        id: 'txn-1', orderId: 'order-1', amount: 12500, sellerAmount: 11250,
        status: 'PENDING', order: {
          buyerId: 'buyer-1', sellerId: 'seller-1', productId: 'product-1', quantity: 1,
          product: { title: 'Existing product' },
        },
      }],
    });
    const module = await Test.createTestingModule({
      providers: [PaymentGroupDatabaseRepository, {
        provide: PrismaService, useValue: { paymentGroup: { findFirst } },
      }],
    }).compile();

    const result = await module.get(PaymentGroupDatabaseRepository).findLatestOpenForBuyer('buyer-1');

    expect(findFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: { buyerId: 'buyer-1', status: 'PENDING' },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    }));
    expect(result.isRight() && result.value).toMatchObject({
      mode: 'intent', group: {
        id: 'group-1', buyerId: 'buyer-1', amount: 12500, stripePaymentIntentId: 'pi_1',
        orders: [{ orderId: 'order-1', productId: 'product-1' }],
      },
    });
  });
});
