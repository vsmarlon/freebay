import { EscrowStatus, OrderStatus, PaymentMethod, PaymentProvider, TransactionStatus } from '@prisma/client';
import { Test, TestingModule } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { prisma } from '../../../../../test/setup-integration';
import { OrderFactory, ProductFactory, UserFactory } from '../../../../../test/factories';
import { OrderDatabaseRepository } from '@/modules/orders/data/repositories/order-database.repository';
import { RefundOrderTxData } from '@/modules/orders/types/order.types';
import { TransactionDatabaseRepository } from './transaction-database.repository';
import { ProcessRefundUseCase } from '../../usecases/process-refund.usecase';
import { SellerPayoutService } from '../../services/seller-payout.service';
import { StripeProvider } from '../../providers/stripe-provider';
import { RefundRecoveryTask } from '@/modules/tasks/refund-recovery.task';

describe('Refund finalization and recovery integration', () => {
  let users: UserFactory;
  let products: ProductFactory;
  let orders: OrderFactory;
  let orderRepository: OrderDatabaseRepository;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrderDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    orderRepository = module.get(OrderDatabaseRepository);
    users = new UserFactory(prisma);
    products = new ProductFactory(prisma);
    orders = new OrderFactory(prisma);
  });

  async function seedRefund() {
    const buyer = await users.createWithWallet();
    const seller = await users.createWithWallet({}, { pendingBalance: 900 });
    const product = await products.create(seller.id, { price: 1000, quantity: 3, soldCount: 1 });
    const order = await orders.createWithAmounts(buyer.id, seller.id, product.id, 1000, 100, 900, {
      status: OrderStatus.CONFIRMED,
      escrowStatus: EscrowStatus.HELD,
    });
    await prisma.order.update({ where: { id: order.id }, data: { cancellationReason: 'refund pending' } });
    const operationId = `refund-operation-${order.id}`;
    const providerId = `re-${order.id}`;
    await prisma.transaction.create({
      data: {
        orderId: order.id,
        externalId: `pi-${order.id}`,
        chargeId: `ch-${order.id}`,
        amount: 1000,
        platformFee: 100,
        sellerAmount: 900,
        paymentMethod: PaymentMethod.CREDIT_CARD,
        provider: PaymentProvider.STRIPE,
        status: TransactionStatus.PAID,
        idempotencyKey: `payment-${order.id}`,
        refundOperationId: operationId,
        refundIdempotencyKey: `refund-key-${order.id}`,
        refundProviderId: providerId,
        refundAmount: 1000,
      },
    });
    return { buyer, seller, product, order, operationId, providerId };
  }

  it('finalizes a concurrent refund once, restoring inventory and debiting escrow once', async () => {
    const { buyer, seller, product, order, operationId, providerId } = await seedRefund();
    const refund: RefundOrderTxData = {
      orderId: order.id,
      productId: product.id,
      buyerId: buyer.id,
      amount: 1000,
      status: OrderStatus.CONFIRMED,
      orderQuantity: order.quantity,
      sellerId: seller.id,
      sellerAmount: 900,
      escrowStatus: 'HELD',
      transferId: null,
      refundOperationId: operationId,
      refundProviderId: providerId,
      refundAmount: 1000,
    };

    const results = await Promise.all([
      orderRepository.refundOrder(refund),
      orderRepository.refundOrder(refund),
    ]);

    expect(results.filter((result) => result.isRight() && result.value)).toHaveLength(1);
    expect(results.filter((result) => result.isRight() && !result.value)).toHaveLength(1);
    expect(await prisma.product.findUniqueOrThrow({ where: { id: product.id } })).toMatchObject({ soldCount: 0, status: 'ACTIVE' });
    expect(await prisma.wallet.findUniqueOrThrow({ where: { userId: seller.id } })).toMatchObject({ pendingBalance: 0 });
    expect(await prisma.walletEntry.count({ where: { userId: seller.id, orderId: order.id } })).toBe(1);
    expect(await prisma.order.findUniqueOrThrow({ where: { id: order.id } })).toMatchObject({ status: OrderStatus.CANCELLED, escrowStatus: EscrowStatus.REFUNDED });
    expect(await prisma.transaction.findUniqueOrThrow({ where: { orderId: order.id } })).toMatchObject({ status: TransactionStatus.REFUNDED, refundOperationId: operationId, refundProviderId: providerId, refundAmount: 1000 });
  });

  it('retries local finalization of a provider-confirmed refund without issuing another provider refund', async () => {
    const { seller, product, order, operationId, providerId } = await seedRefund();
    await prisma.wallet.delete({ where: { userId: seller.id } });

    const canonicalRefund = {
      id: providerId,
      chargeId: `ch-${order.id}`,
      orderId: order.id,
      operationId,
      amount: 1000,
      status: 'succeeded' as const,
    };
    const stripeFake = {
      retrieveRefund: jest.fn(async (refundId: string) => {
        expect(refundId).toBe(providerId);
        return right(canonicalRefund);
      }),
      refundPayment: jest.fn(async () => right(canonicalRefund)),
    };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProcessRefundUseCase,
        TransactionDatabaseRepository,
        OrderDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
        { provide: SellerPayoutService, useValue: { reverseForOrder: jest.fn(async () => right(undefined)) } },
        { provide: StripeProvider, useValue: stripeFake },
      ],
    }).compile();
    const recovery = new RefundRecoveryTask(module.get(ProcessRefundUseCase));

    await recovery.recoverProviderConfirmedRefunds();

    expect(await prisma.order.findUniqueOrThrow({ where: { id: order.id } })).toMatchObject({ status: OrderStatus.CONFIRMED, escrowStatus: EscrowStatus.HELD });
    expect(await prisma.product.findUniqueOrThrow({ where: { id: product.id } })).toMatchObject({ soldCount: 1, status: 'ACTIVE' });
    expect(await prisma.transaction.findUniqueOrThrow({ where: { orderId: order.id } })).toMatchObject({ status: TransactionStatus.PAID, refundOperationId: operationId, refundProviderId: providerId, refundAmount: 1000 });

    await prisma.wallet.create({ data: { userId: seller.id, pendingBalance: 900 } });
    await recovery.recoverProviderConfirmedRefunds();

    expect(stripeFake.retrieveRefund).toHaveBeenCalledTimes(2);
    expect(stripeFake.refundPayment).not.toHaveBeenCalled();
    expect(await prisma.order.findUniqueOrThrow({ where: { id: order.id } })).toMatchObject({ status: OrderStatus.CANCELLED, escrowStatus: EscrowStatus.REFUNDED });
    expect(await prisma.product.findUniqueOrThrow({ where: { id: product.id } })).toMatchObject({ soldCount: 0, status: 'ACTIVE' });
    expect(await prisma.wallet.findUniqueOrThrow({ where: { userId: seller.id } })).toMatchObject({ pendingBalance: 0 });
    expect(await prisma.walletEntry.count({ where: { userId: seller.id, orderId: order.id } })).toBe(1);
    expect(await prisma.transaction.findUniqueOrThrow({ where: { orderId: order.id } })).toMatchObject({ status: TransactionStatus.REFUNDED, refundOperationId: operationId, refundProviderId: providerId, refundAmount: 1000 });
  });
});
