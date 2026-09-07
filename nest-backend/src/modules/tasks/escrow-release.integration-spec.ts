import { WalletEntryReason } from '@prisma/client';
import { prisma } from '../../../test/setup-integration';
import { UserFactory, ProductFactory, OrderFactory } from '../../../test/factories';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { SellerPayoutService } from '@/modules/payments/services/seller-payout.service';
import { applyWalletDelta } from '@/shared/wallet/wallet-mutation';
import { EscrowReleaseTask } from './escrow-release.task';

describe('EscrowReleaseTask Integration', () => {
  let sut: EscrowReleaseTask;
  let payoutService: { payoutForOrder: jest.Mock };
  let userFactory: UserFactory;
  let productFactory: ProductFactory;
  let orderFactory: OrderFactory;

  const EIGHT_DAYS_AGO = () => new Date(Date.now() - 8 * 24 * 60 * 60 * 1000);

  beforeAll(() => {
    userFactory = new UserFactory(prisma);
    productFactory = new ProductFactory(prisma);
    orderFactory = new OrderFactory(prisma);
  });

  beforeEach(() => {
    payoutService = { payoutForOrder: jest.fn().mockResolvedValue(undefined) };
    sut = new EscrowReleaseTask(
      prisma as PrismaService,
      payoutService as unknown as SellerPayoutService,
    );
  });

  async function seedDeliveredOrder() {
    const buyer = await userFactory.create();
    const seller = await userFactory.create();
    const product = await productFactory.create(seller.id, { price: 10000 });
    const order = await orderFactory.create(buyer.id, seller.id, product.id, {
      status: 'DELIVERED',
      escrowStatus: 'HELD',
      deliveryConfirmedAt: EIGHT_DAYS_AGO(),
    });

    await prisma.transaction.create({
      data: {
        orderId: order.id,
        amount: order.amount,
        platformFee: order.platformFee,
        sellerAmount: order.sellerAmount,
        paymentMethod: 'CREDIT_CARD',
        provider: 'STRIPE',
        status: 'PAID',
        idempotencyKey: `escrow-${order.id}`,
        paidAt: new Date(),
      },
    });

    await prisma.$transaction((tx) =>
      applyWalletDelta(
        tx,
        seller.id,
        { pendingBalance: order.sellerAmount },
        { reason: WalletEntryReason.SALE_HELD, orderId: order.id },
      ),
    );

    return { seller, order };
  }

  it('releases escrow and moves the hold into the available balance', async () => {
    const { seller, order } = await seedDeliveredOrder();

    await sut.autoReleaseDeliveredOrders();

    const wallet = await prisma.wallet.findUnique({ where: { userId: seller.id } });
    expect(wallet).toMatchObject({
      pendingBalance: 0,
      availableBalance: order.sellerAmount,
      totalEarned: order.sellerAmount,
    });

    const updated = await prisma.order.findUnique({ where: { id: order.id } });
    expect(updated).toMatchObject({ status: 'COMPLETED', escrowStatus: 'RELEASED' });

    const transaction = await prisma.transaction.findUnique({ where: { orderId: order.id } });
    expect(transaction?.status).toBe('RELEASED');
    expect(payoutService.payoutForOrder).toHaveBeenCalledWith(order.id);
  });

  it('credits the seller exactly once when two ticks run concurrently', async () => {
    const { seller, order } = await seedDeliveredOrder();

    await Promise.all([sut.autoReleaseDeliveredOrders(), sut.autoReleaseDeliveredOrders()]);

    const wallet = await prisma.wallet.findUnique({ where: { userId: seller.id } });
    expect(wallet?.availableBalance).toBe(order.sellerAmount);
    expect(wallet?.pendingBalance).toBe(0);

    const released = await prisma.walletEntry.findMany({
      where: { orderId: order.id, reason: WalletEntryReason.SALE_RELEASED, kind: 'AVAILABLE' },
    });
    expect(released).toHaveLength(1);
  });

  it('leaves escrow alone while a dispute is open', async () => {
    const { seller, order } = await seedDeliveredOrder();
    await prisma.dispute.create({
      data: {
        orderId: order.id,
        openedById: order.buyerId,
        reason: 'Item não recebido',
        status: 'OPEN',
        expiresAt: new Date(Date.now() + 72 * 60 * 60 * 1000),
      },
    });

    await sut.autoReleaseDeliveredOrders();

    const wallet = await prisma.wallet.findUnique({ where: { userId: seller.id } });
    expect(wallet?.availableBalance).toBe(0);
    expect(wallet?.pendingBalance).toBe(order.sellerAmount);

    const untouched = await prisma.order.findUnique({ where: { id: order.id } });
    expect(untouched?.escrowStatus).toBe('HELD');
  });
});
