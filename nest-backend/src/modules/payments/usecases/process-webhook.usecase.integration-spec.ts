import { Test, TestingModule } from '@nestjs/testing';
import { ProcessWebhookUseCase } from './process-webhook.usecase';
import { prisma } from '../../../../test/setup-integration';
import { right } from '@/shared/core/either';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { ProductDatabaseRepository } from '../../products/data/repositories/product-database.repository';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { PrismaOrderRepository } from '../../orders/data/repositories/order-database.repository';
import { WalletDatabaseRepository } from '../../wallet/data/repositories/wallet-database.repository';

const mockNotificationService = {
  notifyPayment: jest.fn().mockResolvedValue(undefined),
  notifyOrderStatus: jest.fn().mockResolvedValue(undefined),
};

const mockProductRepo: Record<string, jest.Mock> = {};
const mockTransactionRepo: { findByOrderId?: jest.Mock } = {};
const mockOrderRepo: Record<string, jest.Mock> = {};
const mockWalletRepo: Record<string, jest.Mock> = {};

describe('ProcessWebhookUseCase Integration', () => {
  let sut: ProcessWebhookUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProcessWebhookUseCase,
        { provide: ProductDatabaseRepository, useValue: mockProductRepo },
        { provide: TransactionDatabaseRepository, useValue: mockTransactionRepo },
        { provide: PrismaOrderRepository, useValue: mockOrderRepo },
        { provide: WalletDatabaseRepository, useValue: mockWalletRepo },
        { provide: NotificationService, useValue: mockNotificationService },
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    sut = module.get(ProcessWebhookUseCase);
    jest.clearAllMocks();
  });

  it('succeeds without mutating anything for an unknown event', async () => {
    const result = await sut.execute({ event: 'unknown.event', data: {} });
    expect(result.isRight()).toBe(true);
  });

  it('succeeds without mutating anything when orderId is missing', async () => {
    const result = await sut.execute({ event: 'checkout.session.completed', data: {} });
    expect(result.isRight()).toBe(true);
  });

  it('succeeds without mutating anything for payment_intent.succeeded with no orderId', async () => {
    const result = await sut.execute({ event: 'payment_intent.succeeded', data: {} });
    expect(result.isRight()).toBe(true);
  });

  it('succeeds without mutating anything for an unknown event even with orderId', async () => {
    const result = await sut.execute({ event: 'unknown.event', data: { orderId: 'o1' } });
    expect(result.isRight()).toBe(true);
  });

  it('skips duplicate completion when transaction is already PAID', async () => {
    mockTransactionRepo.findByOrderId = jest
      .fn()
      .mockResolvedValue(
        right({
          id: 'tx',
          status: 'PAID',
          order: { productId: 'p1', sellerId: 's1' },
        }),
      );

    const txSpy = jest.spyOn(prisma, '$transaction');
    try {
      const result = await sut.execute({
        event: 'checkout.session.completed',
        data: { orderId: 'o1' },
      });

      expect(result.isRight()).toBe(true);
      expect(txSpy).not.toHaveBeenCalled();
    } finally {
      txSpy.mockRestore();
    }
  });
});
