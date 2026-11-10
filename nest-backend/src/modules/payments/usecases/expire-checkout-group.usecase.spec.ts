import { Test, TestingModule } from '@nestjs/testing';
import { ExpireCheckoutGroupUseCase } from './expire-checkout-group.usecase';
import { PaymentGroupDatabaseRepository } from '../data/repositories/payment-group-database.repository';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { ProductDatabaseRepository } from '../../products/data/repositories/product-database.repository';
import { OrderDatabaseRepository } from '../../orders/data/repositories/order-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';
import { StripeProvider } from '../providers/stripe-provider';

const mockPaymentGroupRepository = {
  findExpiredGroupIds: jest.fn(),
  findById: jest.fn(),
  markTerminal: jest.fn(),
};

const mockTransactionRepository = {
  findExpiredPending: jest.fn(),
  markAsFailed: jest.fn(),
};

const mockProductRepository = {
  restoreInventoryOnExpiry: jest.fn(),
};

const mockOrderRepository = {
  cancel: jest.fn(),
  findStaleUnpaidOrders: jest.fn(),
  claimCheckoutAbandoned: jest.fn(),
};

const mockPrisma = {
  $transaction: jest.fn(),
};

const mockStripe = {
  cancelPendingPayment: jest.fn(),
};

const buildGroup = () => ({
  id: 'group-1',
  buyerId: 'buyer-1',
  amount: 10000,
  currency: 'brl',
  status: 'PENDING' as const,
  stripePaymentIntentId: 'pi_1',
  stripeSessionId: null,
  clientSecret: null,
  checkoutUrl: null,
  expiresAt: new Date('2000-01-01T00:00:00.000Z'),
  orders: [
    {
      orderId: 'order-1',
      transactionId: 'tx-1',
      transactionStatus: 'PENDING' as const,
      amount: 10000,
      sellerAmount: 9000,
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: 'product-1',
      productTitle: 'Product 1',
      quantity: 2,
    },
  ],
});

describe('ExpireCheckoutGroupUseCase', () => {
  let sut: ExpireCheckoutGroupUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ExpireCheckoutGroupUseCase,
        { provide: PaymentGroupDatabaseRepository, useValue: mockPaymentGroupRepository },
        { provide: TransactionDatabaseRepository, useValue: mockTransactionRepository },
        { provide: ProductDatabaseRepository, useValue: mockProductRepository },
        { provide: OrderDatabaseRepository, useValue: mockOrderRepository },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: StripeProvider, useValue: mockStripe },
      ],
    }).compile();

    sut = module.get(ExpireCheckoutGroupUseCase);

    mockPaymentGroupRepository.findExpiredGroupIds.mockResolvedValue(right([]));
    mockPaymentGroupRepository.findById.mockResolvedValue(right(buildGroup()));
    mockPaymentGroupRepository.markTerminal.mockResolvedValue(1);
    mockTransactionRepository.findExpiredPending.mockResolvedValue(right([]));
    mockTransactionRepository.markAsFailed.mockResolvedValue(right({ count: 1 }));
    mockProductRepository.restoreInventoryOnExpiry.mockResolvedValue(right(undefined));
    mockOrderRepository.cancel.mockResolvedValue(right(undefined));
    mockOrderRepository.findStaleUnpaidOrders.mockResolvedValue(right([]));
    mockOrderRepository.claimCheckoutAbandoned.mockResolvedValue(right(true));
    mockStripe.cancelPendingPayment.mockResolvedValue(right(undefined));
    mockPrisma.$transaction.mockImplementation((callback: (tx: unknown) => unknown) =>
      Promise.resolve(callback({})),
    );
  });

  it('deve devolver zero reivindicações quando não há nada expirado', async () => {
    const result = await sut.execute();

    expect(result.isRight()).toBe(true);
    expect(mockPaymentGroupRepository.markTerminal).not.toHaveBeenCalled();
    expect(mockOrderRepository.cancel).not.toHaveBeenCalled();
  });

  it('deve devolver o estoque com a quantidade do pedido, não uma unidade', async () => {
    mockPaymentGroupRepository.findExpiredGroupIds.mockResolvedValue(right(['group-1']));

    await sut.execute();

    expect(mockProductRepository.restoreInventoryOnExpiry).toHaveBeenCalledWith(
      'product-1',
      2,
      {},
    );
  });

  it('deve cancelar o pedido e marcar o grupo como expirado', async () => {
    mockPaymentGroupRepository.findExpiredGroupIds.mockResolvedValue(right(['group-1']));

    await sut.execute();

    expect(mockOrderRepository.cancel).toHaveBeenCalledWith('order-1', {});
    expect(mockPaymentGroupRepository.markTerminal).toHaveBeenCalledWith('group-1', 'EXPIRED', {});
    expect(mockOrderRepository.cancel).toHaveBeenCalledTimes(1);
  });

  it('não deve contar o grupo quando outro processo já o expirou', async () => {
    mockPaymentGroupRepository.findExpiredGroupIds.mockResolvedValue(right(['group-1']));
    mockPaymentGroupRepository.markTerminal.mockResolvedValue(0);

    await sut.execute();

    expect(mockOrderRepository.cancel).not.toHaveBeenCalled();
    expect(mockProductRepository.restoreInventoryOnExpiry).not.toHaveBeenCalled();
  });

  it('deve reclamar transações avulsas expiradas sem grupo', async () => {
    mockTransactionRepository.findExpiredPending.mockResolvedValue(
      right([
        { id: 'tx-solo', orderId: 'order-solo', externalId: 'pi_solo', idempotencyKey: 'key-solo', productId: 'product-solo', quantity: 3 },
      ]),
    );

    await sut.execute();

    expect(mockProductRepository.restoreInventoryOnExpiry).toHaveBeenCalledWith(
      'product-solo',
      3,
      {},
    );
    expect(mockOrderRepository.cancel).toHaveBeenCalledWith('order-solo', {});
    expect(mockPaymentGroupRepository.markTerminal).not.toHaveBeenCalled();
  });

  it('não deve liberar estoque se o provedor não confirmou o cancelamento', async () => {
    mockPaymentGroupRepository.findExpiredGroupIds.mockResolvedValue(right(['group-1']));
    mockStripe.cancelPendingPayment.mockResolvedValue(left(new DatabaseError('timeout')));

    await sut.execute();

    expect(mockPaymentGroupRepository.markTerminal).not.toHaveBeenCalled();
    expect(mockOrderRepository.cancel).not.toHaveBeenCalled();
    expect(mockProductRepository.restoreInventoryOnExpiry).not.toHaveBeenCalled();
  });

  it('mantém estoque retido quando o grupo não tem identidade no provedor', async () => {
    mockPaymentGroupRepository.findExpiredGroupIds.mockResolvedValue(right(['group-1']));
    mockPaymentGroupRepository.findById.mockResolvedValue(right({
      ...buildGroup(), stripePaymentIntentId: null,
    }));

    await sut.execute();

    expect(mockStripe.cancelPendingPayment).not.toHaveBeenCalled();
    expect(mockPaymentGroupRepository.markTerminal).not.toHaveBeenCalled();
    expect(mockProductRepository.restoreInventoryOnExpiry).not.toHaveBeenCalled();
  });

  it('não deve reclamar uma transação avulsa que outro processo já falhou', async () => {
    mockTransactionRepository.findExpiredPending.mockResolvedValue(
      right([{ id: 'tx-solo', orderId: 'order-solo', externalId: 'pi_solo', idempotencyKey: 'key-solo', productId: 'product-solo', quantity: 3 }]),
    );
    mockTransactionRepository.markAsFailed.mockResolvedValue(right({ count: 0 }));

    await sut.execute();

    expect(mockProductRepository.restoreInventoryOnExpiry).not.toHaveBeenCalled();
    expect(mockOrderRepository.cancel).not.toHaveBeenCalled();
  });

  it('mantém estoque retido quando uma transação expirada não tem identidade no provedor', async () => {
    mockTransactionRepository.findExpiredPending.mockResolvedValue(right([
      { id: 'tx-orphan', orderId: 'order-orphan', externalId: null, idempotencyKey: 'key-orphan', productId: 'product-orphan', quantity: 1 },
    ]));

    await sut.execute();

    expect(mockStripe.cancelPendingPayment).not.toHaveBeenCalled();
    expect(mockOrderRepository.cancel).not.toHaveBeenCalled();
    expect(mockProductRepository.restoreInventoryOnExpiry).not.toHaveBeenCalled();
  });

  it('deve propagar a falha quando a busca de grupos expirados falha', async () => {
    mockPaymentGroupRepository.findExpiredGroupIds.mockResolvedValue(
      left(new DatabaseError('boom')),
    );

    const result = await sut.execute();

    expect(result.isLeft()).toBe(true);
  });

  it('deve continuar com os demais grupos quando um grupo falha', async () => {
    mockPaymentGroupRepository.findExpiredGroupIds.mockResolvedValue(
      right(['group-broken', 'group-1']),
    );
    mockPaymentGroupRepository.findById
      .mockResolvedValueOnce(left(new DatabaseError('boom')))
      .mockResolvedValueOnce(right(buildGroup()));

    const result = await sut.execute();

    expect(result.isRight()).toBe(true);
    expect(mockOrderRepository.cancel).toHaveBeenCalledTimes(1);
    expect(mockPaymentGroupRepository.markTerminal).toHaveBeenCalledWith('group-1', 'EXPIRED', {});
  });

  describe('stale unpaid orders without a transaction', () => {
    afterEach(() => {
      jest.useRealTimers();
    });

    it('claims the abandoned order and restores inventory without calling the provider', async () => {
      mockOrderRepository.findStaleUnpaidOrders.mockResolvedValue(
        right([{ id: 'order-stale', productId: 'product-stale', quantity: 1 }]),
      );

      const result = await sut.execute();

      expect(result.isRight()).toBe(true);
      expect(mockOrderRepository.claimCheckoutAbandoned).toHaveBeenCalledWith('order-stale', {});
      expect(mockProductRepository.restoreInventoryOnExpiry).toHaveBeenCalledWith(
        'product-stale',
        1,
        {},
      );
      expect(mockStripe.cancelPendingPayment).not.toHaveBeenCalled();
    });

    it('does not restore inventory when the claim updated no rows', async () => {
      mockOrderRepository.findStaleUnpaidOrders.mockResolvedValue(
        right([{ id: 'order-stale', productId: 'product-stale', quantity: 1 }]),
      );
      mockOrderRepository.claimCheckoutAbandoned.mockResolvedValue(right(false));

      await sut.execute();

      expect(mockOrderRepository.claimCheckoutAbandoned).toHaveBeenCalledWith('order-stale', {});
      expect(mockProductRepository.restoreInventoryOnExpiry).not.toHaveBeenCalled();
    });

    it('claims nothing when there are no stale orders', async () => {
      mockOrderRepository.findStaleUnpaidOrders.mockResolvedValue(right([]));

      await sut.execute();

      expect(mockOrderRepository.claimCheckoutAbandoned).not.toHaveBeenCalled();
      expect(mockProductRepository.restoreInventoryOnExpiry).not.toHaveBeenCalled();
    });

    it('only fetches orders created more than 30 minutes ago', async () => {
      jest.useFakeTimers().setSystemTime(new Date('2026-11-06T12:00:00.000Z'));

      await sut.execute();

      expect(mockOrderRepository.findStaleUnpaidOrders).toHaveBeenCalledWith(
        new Date('2026-11-06T11:30:00.000Z'),
      );
    });

    it('propagates the failure when the stale-order lookup fails', async () => {
      mockOrderRepository.findStaleUnpaidOrders.mockResolvedValue(
        left(new DatabaseError('boom')),
      );

      const result = await sut.execute();

      expect(result.isLeft()).toBe(true);
    });
  });
});
