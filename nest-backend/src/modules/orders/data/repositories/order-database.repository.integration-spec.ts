import { EscrowStatus, OrderStatus } from '@prisma/client';
import { Test, TestingModule } from '@nestjs/testing';
import { prisma } from '../../../../../test/setup-integration';
import { UserFactory, ProductFactory, OrderFactory } from '../../../../../test/factories';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PrismaOrderRepository } from './order-database.repository';
import { RefundOrderTxData } from '../../types/order.types';

describe('PrismaOrderRepository.refundOrder', () => {
  let repository: PrismaOrderRepository;
  let userFactory: UserFactory;
  let productFactory: ProductFactory;
  let orderFactory: OrderFactory;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [PrismaOrderRepository, { provide: PrismaService, useValue: prisma }],
    }).compile();
    repository = module.get(PrismaOrderRepository);
    userFactory = new UserFactory(prisma);
    productFactory = new ProductFactory(prisma);
    orderFactory = new OrderFactory(prisma);
  });

  async function refund(
    status: OrderStatus,
    escrowStatus: EscrowStatus,
    transferId: string | null,
  ) {
    const buyer = await userFactory.createWithWallet();
    const seller = await userFactory.createWithWallet();
    const product = await productFactory.create(seller.id, { price: 1000 });
    const order = await orderFactory.createWithAmounts(
      buyer.id,
      seller.id,
      product.id,
      1000,
      100,
      900,
      { status, escrowStatus },
    );
    await prisma.wallet.update({
      where: { userId: seller.id },
      data:
        escrowStatus === EscrowStatus.RELEASED
          ? transferId
            ? {}
            : { availableBalance: 900, totalEarned: 900 }
          : { pendingBalance: 900 },
    });

    const data: RefundOrderTxData = {
      orderId: order.id,
      productId: product.id,
      buyerId: buyer.id,
      amount: 1000,
      status,
      orderQuantity: 1,
      sellerId: seller.id,
      sellerAmount: 900,
      escrowStatus: escrowStatus === EscrowStatus.RELEASED ? 'RELEASED' : 'HELD',
      transferId,
    };

    return {
      buyer,
      seller,
      order,
      first: await repository.refundOrder(data),
      second: await repository.refundOrder(data),
    };
  }

  it('does not debit the seller again after a Stripe transfer', async () => {
    const result = await refund(OrderStatus.COMPLETED, EscrowStatus.RELEASED, 'tr_1');

    expect(result.first.isRight()).toBe(true);
    expect(result.second.isRight()).toBe(true);
    expect(await prisma.wallet.findUnique({ where: { userId: result.seller.id } })).toMatchObject({
      availableBalance: 0,
      totalEarned: 0,
    });
    expect(await prisma.walletEntry.count({ where: { orderId: result.order.id } })).toBe(1);
  });

  it('debits available and earned balances when released funds were not transferred', async () => {
    const result = await refund(OrderStatus.COMPLETED, EscrowStatus.RELEASED, null);

    const retry = await repository.refundOrder({
      orderId: result.order.id,
      productId: result.order.productId,
      buyerId: result.buyer.id,
      amount: 1000,
      status: OrderStatus.COMPLETED,
      orderQuantity: 1,
      sellerId: result.seller.id,
      sellerAmount: 900,
      escrowStatus: 'RELEASED',
      transferId: null,
    });

    expect(retry.isRight()).toBe(true);
    expect(await prisma.wallet.findUnique({ where: { userId: result.seller.id } })).toMatchObject({
      availableBalance: 0,
      totalEarned: 0,
    });
    expect(await prisma.walletEntry.count({ where: { orderId: result.order.id } })).toBe(3);
  });

  it('debits pending escrow only and does not add entries on retry', async () => {
    const result = await refund(OrderStatus.CONFIRMED, EscrowStatus.HELD, null);

    const retry = await repository.refundOrder({
      orderId: result.order.id,
      productId: result.order.productId,
      buyerId: result.buyer.id,
      amount: 1000,
      status: OrderStatus.CONFIRMED,
      orderQuantity: 1,
      sellerId: result.seller.id,
      sellerAmount: 900,
      escrowStatus: 'HELD',
      transferId: null,
    });

    expect(retry.isRight()).toBe(true);
    expect(await prisma.wallet.findUnique({ where: { userId: result.seller.id } })).toMatchObject({
      availableBalance: 0,
      pendingBalance: 0,
    });
    expect(await prisma.walletEntry.count({ where: { orderId: result.order.id } })).toBe(2);
  });
});
