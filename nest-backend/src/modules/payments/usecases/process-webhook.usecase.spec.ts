import { Test, TestingModule } from '@nestjs/testing';
import { ProcessWebhookUseCase } from './process-webhook.usecase';
import { right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { NotificationService } from '../../notifications/services/notification.service';
import { ProductDatabaseRepository } from '../../products/data/repositories/product-database.repository';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { PrismaOrderRepository } from '../../orders/data/repositories/order-database.repository';
import { WalletDatabaseRepository } from '../../wallet/data/repositories/wallet-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

const tx = {} as never;

describe('ProcessWebhookUseCase', () => {
  let sut: ProcessWebhookUseCase;
  let mockProductRepo: {
    updateInventoryOnSale: jest.Mock;
    restoreInventoryOnExpiry: jest.Mock;
  };
  let mockTransactionRepo: {
    findByOrderId: jest.Mock;
    markAsPaid: jest.Mock;
    markAsFailed: jest.Mock;
  };
  let mockOrderRepo: { confirm: jest.Mock; cancel: jest.Mock };
  let mockWalletRepo: { creditPending: jest.Mock };
  let mockNotificationService: {
    notifyPayment: jest.Mock;
    notifyOrderStatus: jest.Mock;
  };
  let mockPrisma: { $transaction: jest.Mock };

  const paidTransaction = {
    id: 'tx-paid',
    orderId: 'o1',
    status: 'PAID',
    amount: 10000,
    sellerAmount: 9000,
    order: { productId: 'p1', sellerId: 's1', buyerId: 'b1', quantity: 3, status: 'PENDING' },
  };

  const pendingTransaction = {
    id: 'tx-pending',
    orderId: 'o1',
    status: 'PENDING',
    amount: 10000,
    sellerAmount: 9000,
    order: { productId: 'p1', sellerId: 's1', buyerId: 'b1', quantity: 3, status: 'PENDING' },
  };

  const failedTransaction = {
    id: 'tx-failed',
    orderId: 'o1',
    status: 'FAILED',
    amount: 10000,
    sellerAmount: 9000,
    order: { productId: 'p1', sellerId: 's1', buyerId: 'b1', quantity: 3, status: 'PENDING' },
  };

  beforeEach(async () => {
    mockProductRepo = {
      updateInventoryOnSale: jest.fn().mockResolvedValue(right(undefined)),
      restoreInventoryOnExpiry: jest.fn().mockResolvedValue(right(undefined)),
    };
    mockTransactionRepo = {
      findByOrderId: jest.fn(),
      markAsPaid: jest.fn().mockResolvedValue(right({ count: 1 })),
      markAsFailed: jest.fn().mockResolvedValue(right({ count: 1 })),
    };
    mockOrderRepo = {
      confirm: jest.fn().mockResolvedValue(right(true)),
      cancel: jest.fn().mockResolvedValue(right(undefined)),
    };
    mockWalletRepo = {
      creditPending: jest.fn().mockResolvedValue(right(undefined)),
    };
    mockNotificationService = {
      notifyPayment: jest.fn().mockResolvedValue(undefined),
      notifyOrderStatus: jest.fn().mockResolvedValue(undefined),
    };
    mockPrisma = {
      $transaction: jest.fn(async (fn: (client: typeof tx) => Promise<unknown>) => fn(tx)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProcessWebhookUseCase,
        { provide: ProductDatabaseRepository, useValue: mockProductRepo },
        { provide: TransactionDatabaseRepository, useValue: mockTransactionRepo },
        { provide: PrismaOrderRepository, useValue: mockOrderRepo },
        { provide: WalletDatabaseRepository, useValue: mockWalletRepo },
        { provide: NotificationService, useValue: mockNotificationService },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get(ProcessWebhookUseCase);
  });

  it.each(['checkout.session.completed', 'payment_intent.succeeded'])(
    'skips duplicate completion when transaction is already PAID for %s',
    async (event) => {
      mockTransactionRepo.findByOrderId.mockResolvedValue(right(paidTransaction));

      const result = await sut.execute({ event, data: { orderId: 'o1' } });

      expect(result.isRight()).toBe(true);
      expect(mockPrisma.$transaction).not.toHaveBeenCalled();
      expect(mockTransactionRepo.markAsPaid).not.toHaveBeenCalled();
      expect(mockNotificationService.notifyPayment).not.toHaveBeenCalled();
      expect(mockNotificationService.notifyOrderStatus).not.toHaveBeenCalled();
    },
  );

  it.each(['checkout.session.expired', 'payment_intent.canceled'])(
    'marks failed, cancels order and restores inventory for %s',
    async (event) => {
      mockTransactionRepo.findByOrderId.mockResolvedValue(right(pendingTransaction));

      const result = await sut.execute({ event, data: { orderId: 'o1' } });

      expect(result.isRight()).toBe(true);
      expect(mockTransactionRepo.markAsFailed).toHaveBeenCalledWith('tx-pending', tx);
      expect(mockOrderRepo.cancel).toHaveBeenCalledWith('o1', tx);
      expect(mockProductRepo.restoreInventoryOnExpiry).toHaveBeenCalledWith('p1', 3, tx);
      expect(mockTransactionRepo.markAsPaid).not.toHaveBeenCalled();
      expect(mockNotificationService.notifyPayment).not.toHaveBeenCalled();
    },
  );

  it('does not mutate anything for payment_intent.payment_failed', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(right(pendingTransaction));

    const result = await sut.execute({
      event: 'payment_intent.payment_failed',
      data: { orderId: 'o1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    expect(mockTransactionRepo.markAsFailed).not.toHaveBeenCalled();
    expect(mockTransactionRepo.markAsPaid).not.toHaveBeenCalled();
  });

  it('does not query or mutate for unknown events even with an orderId', async () => {
    const result = await sut.execute({ event: 'charge.refunded', data: { orderId: 'o1' } });

    expect(result.isRight()).toBe(true);
    expect(mockTransactionRepo.findByOrderId).not.toHaveBeenCalled();
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });

  it('does not query or mutate when orderId is missing', async () => {
    const result = await sut.execute({ event: 'payment_intent.succeeded', data: {} });

    expect(result.isRight()).toBe(true);
    expect(mockTransactionRepo.findByOrderId).not.toHaveBeenCalled();
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });

  it('does not mutate anything when no transaction exists for the order', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(right(null));

    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { orderId: 'o1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    expect(mockNotificationService.notifyPayment).not.toHaveBeenCalled();
  });

  it('surfaces a DatabaseError when the completion transaction fails', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(right(pendingTransaction));
    mockPrisma.$transaction.mockRejectedValue(new Error('db exploded'));

    const result = await sut.execute({
      event: 'checkout.session.completed',
      data: { orderId: 'o1' },
    });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(DatabaseError);
    expect(mockNotificationService.notifyPayment).not.toHaveBeenCalled();
  });

  it('marks paid, confirms order, credits wallet and notifies on completion', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(right(pendingTransaction));

    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { orderId: 'o1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockProductRepo.updateInventoryOnSale).toHaveBeenCalledWith('p1', tx);
    expect(mockTransactionRepo.markAsPaid).toHaveBeenCalledWith('tx-pending', null, tx);
    expect(mockOrderRepo.confirm).toHaveBeenCalledWith('o1', tx);
    expect(mockWalletRepo.creditPending).toHaveBeenCalledWith('s1', 9000, 'o1', tx);
    expect(mockNotificationService.notifyPayment).toHaveBeenCalledWith('s1', 10000);
    expect(mockNotificationService.notifyOrderStatus).toHaveBeenCalledWith('b1', 'o1', 'CONFIRMED');
    expect(mockTransactionRepo.markAsFailed).not.toHaveBeenCalled();
  });

  it('processes the first completion and skips the duplicate on the second call', async () => {
    mockTransactionRepo.findByOrderId
      .mockResolvedValueOnce(right(pendingTransaction))
      .mockResolvedValueOnce(right(paidTransaction));

    const first = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { orderId: 'o1' },
    });
    const second = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { orderId: 'o1' },
    });

    expect(first.isRight()).toBe(true);
    expect(second.isRight()).toBe(true);
    expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
    expect(mockTransactionRepo.markAsPaid).toHaveBeenCalledTimes(1);
    expect(mockNotificationService.notifyPayment).toHaveBeenCalledTimes(1);
    expect(mockNotificationService.notifyOrderStatus).toHaveBeenCalledTimes(1);
  });

  it('rolls back and credits nothing when the paid transition loses the race', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(right(pendingTransaction));
    mockTransactionRepo.markAsPaid.mockResolvedValue(right({ count: 0 }));

    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { orderId: 'o1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
    expect(mockProductRepo.updateInventoryOnSale).not.toHaveBeenCalled();
    expect(mockOrderRepo.confirm).not.toHaveBeenCalled();
    expect(mockWalletRepo.creditPending).not.toHaveBeenCalled();
    expect(mockNotificationService.notifyPayment).not.toHaveBeenCalled();
    expect(mockNotificationService.notifyOrderStatus).not.toHaveBeenCalled();
  });

  it('never credits a FAILED transaction that receives a success event', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(right(failedTransaction));

    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { orderId: 'o1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    expect(mockTransactionRepo.markAsPaid).not.toHaveBeenCalled();
    expect(mockOrderRepo.confirm).not.toHaveBeenCalled();
    expect(mockWalletRepo.creditPending).not.toHaveBeenCalled();
    expect(mockNotificationService.notifyPayment).not.toHaveBeenCalled();
  });

  it('does not cancel the order when the failed transition loses the race', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(right(pendingTransaction));
    mockTransactionRepo.markAsFailed.mockResolvedValue(right({ count: 0 }));

    const result = await sut.execute({
      event: 'checkout.session.expired',
      data: { orderId: 'o1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockPrisma.$transaction).toHaveBeenCalledTimes(1);
    expect(mockOrderRepo.cancel).not.toHaveBeenCalled();
    expect(mockProductRepo.restoreInventoryOnExpiry).not.toHaveBeenCalled();
  });

  it('never cancels a PAID order when a late expiry event arrives', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(right(paidTransaction));

    const result = await sut.execute({
      event: 'checkout.session.expired',
      data: { orderId: 'o1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    expect(mockTransactionRepo.markAsFailed).not.toHaveBeenCalled();
    expect(mockOrderRepo.cancel).not.toHaveBeenCalled();
  });

  it('refuses to cancel an order that is no longer PENDING on expiry', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(
      right({ ...pendingTransaction, order: { ...pendingTransaction.order, status: 'DELIVERED' } }),
    );

    const result = await sut.execute({ event: 'checkout.session.expired', data: { orderId: 'o1' } });

    expect(result.isRight()).toBe(true);
    expect(mockOrderRepo.cancel).not.toHaveBeenCalled();
    expect(mockProductRepo.restoreInventoryOnExpiry).not.toHaveBeenCalled();
  });

  it('ignores an expiry that references a different provider object than the transaction holds', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(
      right({ ...pendingTransaction, externalId: 'cs_current' }),
    );

    const result = await sut.execute({
      event: 'checkout.session.expired',
      data: { orderId: 'o1', providerObjectId: 'cs_stale' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockOrderRepo.cancel).not.toHaveBeenCalled();
  });

  it('does not credit the seller when the order confirm claim finds no PENDING row', async () => {
    mockTransactionRepo.findByOrderId.mockResolvedValue(right(pendingTransaction));
    mockOrderRepo.confirm.mockResolvedValue(right(false));

    const result = await sut.execute({ event: 'payment_intent.succeeded', data: { orderId: 'o1' } });

    expect(result.isRight()).toBe(true);
    expect(mockWalletRepo.creditPending).not.toHaveBeenCalled();
    expect(mockNotificationService.notifyPayment).not.toHaveBeenCalled();
  });
});
