import { ProcessWebhookUseCase } from './process-webhook.usecase';
import { prisma } from '../../../../test/setup-integration';
import { isRight } from '@/shared/core/either';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { NotificationService } from '../../notifications/services/notification.service';
import { ProductRepository } from '../../products/domain/repositories/product.repository';
import { TransactionRepository } from '../domain/repositories/transaction.repository';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { WalletRepository } from '../../wallet/domain/repositories/wallet.repository';

const mockNotificationService = {
  notifyPayment: jest.fn().mockResolvedValue(undefined),
  notifyOrderStatus: jest.fn().mockResolvedValue(undefined),
} as unknown as NotificationService;

const mockProductRepo = {} as ProductRepository;
const mockTransactionRepo = {} as TransactionRepository;
const mockOrderRepo = {} as OrderRepository;
const mockWalletRepo = {} as WalletRepository;

describe('ProcessWebhookUseCase Integration', () => {
  let sut: ProcessWebhookUseCase;

  beforeEach(() => {
    sut = new ProcessWebhookUseCase(
      mockProductRepo,
      mockTransactionRepo,
      mockOrderRepo,
      mockWalletRepo,
      mockNotificationService,
      prisma as PrismaService,
    );
    jest.clearAllMocks();
  });

  it('should return processed false for unknown event', async () => {
    const result = await sut.execute({ event: 'unknown.event', data: {} });
    expect(isRight(result)).toBe(true);
    if (isRight(result)) expect(result.value.processed).toBe(false);
  });

  it('should return processed false when no correlationID', async () => {
    const result = await sut.execute({ event: 'charge.completed', data: {} });
    expect(isRight(result)).toBe(true);
    if (isRight(result)) expect(result.value.processed).toBe(false);
  });
});
