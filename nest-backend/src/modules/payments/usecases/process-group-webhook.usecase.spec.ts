import { Test, TestingModule } from '@nestjs/testing';
import { ProcessGroupWebhookUseCase } from './process-group-webhook.usecase';
import { PaymentGroupRepository } from '../domain/repositories/payment-group.repository';
import { TransactionRepository } from '../domain/repositories/transaction.repository';
import { ProductRepository } from '../../products/domain/repositories/product.repository';
import { OrderRepository } from '../../orders/domain/repositories/order.repository';
import { WalletRepository } from '../../wallet/domain/repositories/wallet.repository';
import { NotificationService } from '../../notifications/services/notification.service';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { left, right } from '@/shared/core/either';

const buildOrderRow = (index: number) => ({
  orderId: `order-${index}`,
  transactionId: `tx-${index}`,
  transactionStatus: 'PENDING' as const,
  amount: 10000,
  sellerAmount: 9000,
  buyerId: 'buyer-1',
  sellerId: `seller-${index}`,
  productId: `product-${index}`,
  productTitle: `Product ${index}`,
  quantity: 1,
});

const buildGroup = (overrides: Record<string, unknown> = {}) => ({
  id: 'group-1',
  buyerId: 'buyer-1',
  amount: 30000,
  currency: 'brl',
  status: 'PENDING' as const,
  stripePaymentIntentId: 'pi_1',
  stripeSessionId: null,
  clientSecret: 'pi_1_secret',
  checkoutUrl: null,
  expiresAt: new Date('2100-01-01T00:00:00.000Z'),
  orders: [buildOrderRow(1), buildOrderRow(2), buildOrderRow(3)],
  ...overrides,
});

const mockPaymentGroupRepository = {
  findById: jest.fn(),
  claimPaid: jest.fn(),
  markTerminal: jest.fn(),
};

const mockTransactionRepository = {
  markAsPaid: jest.fn(),
  markAsFailed: jest.fn(),
};

const mockProductRepository = {
  updateInventoryOnSale: jest.fn(),
  restoreInventoryOnExpiry: jest.fn(),
};

const mockOrderRepository = {
  confirm: jest.fn(),
  cancel: jest.fn(),
};

const mockWalletRepository = {
  creditPending: jest.fn(),
};

const mockNotificationService = {
  notifyPayment: jest.fn(),
  notifyOrderStatus: jest.fn(),
};

const mockPrisma = {
  $transaction: jest.fn(),
};

describe('ProcessGroupWebhookUseCase', () => {
  let sut: ProcessGroupWebhookUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProcessGroupWebhookUseCase,
        { provide: PaymentGroupRepository, useValue: mockPaymentGroupRepository },
        { provide: TransactionRepository, useValue: mockTransactionRepository },
        { provide: ProductRepository, useValue: mockProductRepository },
        { provide: OrderRepository, useValue: mockOrderRepository },
        { provide: WalletRepository, useValue: mockWalletRepository },
        { provide: NotificationService, useValue: mockNotificationService },
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get(ProcessGroupWebhookUseCase);

    mockPaymentGroupRepository.findById.mockResolvedValue(right(buildGroup()));
    mockPaymentGroupRepository.claimPaid.mockResolvedValue(1);
    mockPaymentGroupRepository.markTerminal.mockResolvedValue(1);
    mockTransactionRepository.markAsPaid.mockResolvedValue(right({ count: 1 }));
    mockTransactionRepository.markAsFailed.mockResolvedValue(right({ count: 1 }));
    mockProductRepository.updateInventoryOnSale.mockResolvedValue(right(undefined));
    mockProductRepository.restoreInventoryOnExpiry.mockResolvedValue(right(undefined));
    mockOrderRepository.confirm.mockResolvedValue(right(undefined));
    mockOrderRepository.cancel.mockResolvedValue(right(undefined));
    mockWalletRepository.creditPending.mockResolvedValue(right(undefined));
    mockNotificationService.notifyPayment.mockResolvedValue(undefined);
    mockNotificationService.notifyOrderStatus.mockResolvedValue(undefined);
    mockPrisma.$transaction.mockImplementation((callback: (tx: unknown) => unknown) =>
      Promise.resolve(callback({})),
    );
  });

  it('deve creditar cada vendedor exatamente uma vez quando o pagamento é concluído', async () => {
    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { paymentGroupId: 'group-1', amountTotal: 30000, currency: 'brl', chargeId: 'ch_1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockWalletRepository.creditPending).toHaveBeenCalledTimes(3);
    expect(mockWalletRepository.creditPending).toHaveBeenCalledWith('seller-1', 9000, 'order-1', {});
    expect(mockWalletRepository.creditPending).toHaveBeenCalledWith('seller-2', 9000, 'order-2', {});
    expect(mockWalletRepository.creditPending).toHaveBeenCalledWith('seller-3', 9000, 'order-3', {});
  });

  it('deve confirmar cada pedido do grupo', async () => {
    await sut.execute({
      event: 'payment_intent.succeeded',
      data: { paymentGroupId: 'group-1', amountTotal: 30000, chargeId: 'ch_1' },
    });

    expect(mockOrderRepository.confirm).toHaveBeenCalledTimes(3);
  });

  it('não deve creditar ninguém quando outra entrega já reivindicou o grupo', async () => {
    mockPaymentGroupRepository.claimPaid.mockResolvedValue(0);

    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { paymentGroupId: 'group-1', amountTotal: 30000, chargeId: 'ch_1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockWalletRepository.creditPending).not.toHaveBeenCalled();
  });

  it('deve recusar quando o total do webhook não bate com a soma dos pedidos', async () => {
    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { paymentGroupId: 'group-1', amountTotal: 29999, chargeId: 'ch_1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockWalletRepository.creditPending).not.toHaveBeenCalled();
    expect(mockPaymentGroupRepository.claimPaid).not.toHaveBeenCalled();
  });

  it('deve aceitar quando o total do webhook bate exatamente com a soma dos pedidos', async () => {
    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { paymentGroupId: 'group-1', amountTotal: 30000, chargeId: 'ch_1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockPaymentGroupRepository.claimPaid).toHaveBeenCalledWith('group-1', 'ch_1', {});
    expect(mockWalletRepository.creditPending).toHaveBeenCalledTimes(3);
  });

  it('deve recusar quando a moeda não é brl', async () => {
    await sut.execute({
      event: 'payment_intent.succeeded',
      data: { paymentGroupId: 'group-1', amountTotal: 30000, currency: 'usd', chargeId: 'ch_1' },
    });

    expect(mockWalletRepository.creditPending).not.toHaveBeenCalled();
    expect(mockPaymentGroupRepository.claimPaid).not.toHaveBeenCalled();
  });

  it('deve recusar quando o objeto da Stripe não é o do grupo', async () => {
    await sut.execute({
      event: 'payment_intent.succeeded',
      data: {
        paymentGroupId: 'group-1',
        providerObjectId: 'pi_outro',
        amountTotal: 30000,
        chargeId: 'ch_1',
      },
    });

    expect(mockWalletRepository.creditPending).not.toHaveBeenCalled();
    expect(mockPaymentGroupRepository.claimPaid).not.toHaveBeenCalled();
  });

  it('deve tratar como processado quando o grupo já está PAID', async () => {
    mockPaymentGroupRepository.findById.mockResolvedValue(right(buildGroup({ status: 'PAID' })));

    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { paymentGroupId: 'group-1', amountTotal: 30000, chargeId: 'ch_1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockPaymentGroupRepository.claimPaid).not.toHaveBeenCalled();
  });

  it('não deve creditar ninguém quando o grupo não existe', async () => {
    mockPaymentGroupRepository.findById.mockResolvedValue(right(null));

    await sut.execute({
      event: 'payment_intent.succeeded',
      data: { paymentGroupId: 'group-1', amountTotal: 30000 },
    });

    expect(mockWalletRepository.creditPending).not.toHaveBeenCalled();
  });

  it('deve devolver a falha quando a leitura do grupo falha', async () => {
    mockPaymentGroupRepository.findById.mockResolvedValue(left(new Error('boom') as never));

    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { paymentGroupId: 'group-1', amountTotal: 30000 },
    });

    expect(result.isLeft()).toBe(true);
  });

  it('deve devolver o estoque de todos os pedidos quando o checkout expira', async () => {
    const result = await sut.execute({
      event: 'checkout.session.expired',
      data: { paymentGroupId: 'group-1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockProductRepository.restoreInventoryOnExpiry).toHaveBeenCalledTimes(3);
    expect(mockOrderRepository.cancel).toHaveBeenCalledTimes(3);
    expect(mockPaymentGroupRepository.markTerminal).toHaveBeenCalledWith('group-1', 'EXPIRED', {});
  });

  it('não deve devolver estoque quando outra entrega já expirou o grupo', async () => {
    mockPaymentGroupRepository.markTerminal.mockResolvedValue(0);

    const result = await sut.execute({
      event: 'checkout.session.expired',
      data: { paymentGroupId: 'group-1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockProductRepository.restoreInventoryOnExpiry).not.toHaveBeenCalled();
  });

  it('não deve expirar um grupo já pago', async () => {
    mockPaymentGroupRepository.findById.mockResolvedValue(right(buildGroup({ status: 'PAID' })));

    const result = await sut.execute({
      event: 'checkout.session.expired',
      data: { paymentGroupId: 'group-1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockProductRepository.restoreInventoryOnExpiry).not.toHaveBeenCalled();
  });

  it('deve ignorar um evento que não é conclusão nem expiração', async () => {
    await sut.execute({
      event: 'payment_intent.payment_failed',
      data: { paymentGroupId: 'group-1' },
    });

    expect(mockWalletRepository.creditPending).not.toHaveBeenCalled();
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });

  it('deve continuar processado quando as notificações falham', async () => {
    mockNotificationService.notifyPayment.mockRejectedValue(new Error('fcm down'));

    const result = await sut.execute({
      event: 'payment_intent.succeeded',
      data: { paymentGroupId: 'group-1', amountTotal: 30000, chargeId: 'ch_1' },
    });

    expect(result.isRight()).toBe(true);
    expect(mockWalletRepository.creditPending).toHaveBeenCalledTimes(3);
  });
});
