import { Test, TestingModule } from '@nestjs/testing';
import { ExpireCheckoutGroupUseCase } from './expire-checkout-group.usecase';
import { PaymentGroupDatabaseRepository } from '../data/repositories/payment-group-database.repository';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { ProductDatabaseRepository } from '../../products/data/repositories/product-database.repository';
import { PrismaOrderRepository } from '../../orders/data/repositories/order-database.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { left, right } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';

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
};

const mockPrisma = {
  $transaction: jest.fn(),
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
        { provide: PrismaOrderRepository, useValue: mockOrderRepository },
        { provide: PrismaService, useValue: mockPrisma },
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
        { id: 'tx-solo', orderId: 'order-solo', productId: 'product-solo', quantity: 3 },
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

  it('não deve reclamar uma transação avulsa que outro processo já falhou', async () => {
    mockTransactionRepository.findExpiredPending.mockResolvedValue(
      right([{ id: 'tx-solo', orderId: 'order-solo', productId: 'product-solo', quantity: 3 }]),
    );
    mockTransactionRepository.markAsFailed.mockResolvedValue(right({ count: 0 }));

    await sut.execute();

    expect(mockProductRepository.restoreInventoryOnExpiry).not.toHaveBeenCalled();
    expect(mockOrderRepository.cancel).not.toHaveBeenCalled();
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
});
