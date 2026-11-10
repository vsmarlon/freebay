import { Test, TestingModule } from '@nestjs/testing';
import { CheckoutCartUseCase } from './checkout-cart.usecase';
import { CartDatabaseRepository } from '../data/repositories/cart-database.repository';
import { PaymentGroupDatabaseRepository } from '@/modules/payments/data/repositories/payment-group-database.repository';
import { StripeProvider } from '@/modules/payments/providers/stripe-provider';
import { UserDatabaseRepository } from '@/modules/users';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { left, right } from '@/shared/core/either';
import { BadRequestError, DatabaseError } from '@/shared/core/errors';
import { PaymentSessionParams, PaymentSessionSnapshot } from '@/modules/payments/types/payment-provider.types';
import { CheckoutMode } from '../dtos/cart.dto';

const mockCartRepository = {
  findUserCpf: jest.fn(),
  getUserCart: jest.fn(),
  reserveAndCreateOrder: jest.fn(),
  restoreOrderReservation: jest.fn(),
  clear: jest.fn(),
};

const mockPaymentGroupRepository = {
  create: jest.fn(),
  findByIdempotencyKey: jest.fn(),
  findLatestOpenForBuyer: jest.fn(),
  findPendingForBuyer: jest.fn(),
  attachPayment: jest.fn(),
  markTerminal: jest.fn(),
};

const mockPaymentProvider = {
  createPaymentSession: jest.fn(),
  retrievePaymentSession: jest.fn(),
  createPaymentIntent: jest.fn(),
  cancelPendingPayment: jest.fn(),
};

const mockUserRepository = {
  findPaymentInfo: jest.fn(),
};

const mockPrisma = {
  $transaction: jest.fn(),
};

const buildCartItem = (overrides: Record<string, unknown> = {}) => ({
  productId: 'product-1',
  quantity: 1,
  ...overrides,
  product: {
    id: 'product-1',
    sellerId: 'seller-1',
    title: 'iPhone 15',
    status: 'ACTIVE',
    price: 10000,
    quantity: 5,
    soldCount: 0,
    ...((overrides.product as Record<string, unknown>) ?? {}),
  },
});

describe('CheckoutCartUseCase', () => {
  let sut: CheckoutCartUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CheckoutCartUseCase,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: CartDatabaseRepository, useValue: mockCartRepository },
        { provide: PaymentGroupDatabaseRepository, useValue: mockPaymentGroupRepository },
        { provide: UserDatabaseRepository, useValue: mockUserRepository },
        { provide: StripeProvider, useValue: mockPaymentProvider },
      ],
    }).compile();

    sut = module.get(CheckoutCartUseCase);

    mockCartRepository.findUserCpf.mockResolvedValue(right('12345678901'));
    mockCartRepository.getUserCart.mockResolvedValue(right([buildCartItem()]));
    mockCartRepository.reserveAndCreateOrder.mockResolvedValue({ id: 'order-1' });
    mockCartRepository.clear.mockResolvedValue(right(undefined));
    mockPaymentGroupRepository.findByIdempotencyKey.mockResolvedValue(right(null));
    mockPaymentGroupRepository.findLatestOpenForBuyer.mockResolvedValue(right(null));
    mockPaymentGroupRepository.findPendingForBuyer.mockResolvedValue(right(null));
    mockPaymentGroupRepository.create.mockResolvedValue({ id: 'group-1' });
    mockPaymentGroupRepository.attachPayment.mockResolvedValue(right(undefined));
    mockPaymentGroupRepository.markTerminal.mockResolvedValue(1);
    mockUserRepository.findPaymentInfo.mockResolvedValue(
      right({ displayName: 'Buyer', email: 'buyer@example.com', cpf: '12345678901' }),
    );
    mockPaymentProvider.createPaymentSession.mockImplementation(async (params: PaymentSessionParams) => {
      mockPaymentProvider.retrievePaymentSession.mockResolvedValue(right<never, PaymentSessionSnapshot>({
        stripeSessionId: 'cs_1',
        checkoutUrl: 'https://checkout.stripe.com/cs_1',
        status: 'open', mode: 'payment', paymentStatus: 'unpaid', amountTotal: params.amount,
        currency: params.currency, orderId: null, paymentGroupId: params.paymentGroupId ?? null,
        buyerId: params.buyerId ?? null, idempotencyKey: params.idempotencyKey ?? null,
        expiresAt: params.expiresAt ?? null,
      }));
      return right({
        stripeSessionId: 'cs_1',
        checkoutUrl: 'https://checkout.stripe.com/cs_1',
        expiresAt: params.expiresAt ?? new Date('2026-01-01T01:00:00.000Z'),
      });
    });
    mockPaymentProvider.createPaymentIntent.mockResolvedValue(
      right({ paymentIntentId: 'pi_1', clientSecret: 'pi_1_secret' }),
    );
    mockPaymentProvider.cancelPendingPayment.mockResolvedValue(right(undefined));
    mockPrisma.$transaction.mockImplementation((callback: (tx: unknown) => unknown) =>
      Promise.resolve(callback({ $queryRaw: jest.fn().mockResolvedValue([{ id: 'buyer-1' }]) })),
    );
  });

  it('deve rejeitar quando o carrinho está vazio', async () => {
    mockCartRepository.getUserCart.mockResolvedValue(right([]));

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(BadRequestError);
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });

  it('deve rejeitar quando o comprador é o vendedor de um dos itens', async () => {
    mockCartRepository.getUserCart.mockResolvedValue(
      right([buildCartItem({ product: { sellerId: 'buyer-1' } })]),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isLeft()).toBe(true);
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });

  it('deve rejeitar quando um produto não está ACTIVE', async () => {
    mockCartRepository.getUserCart.mockResolvedValue(
      right([buildCartItem({ product: { status: 'PAUSED' } })]),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isLeft()).toBe(true);
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });

  it('deve rejeitar quando a quantidade pedida excede o estoque disponível em uma unidade', async () => {
    mockCartRepository.getUserCart.mockResolvedValue(
      right([buildCartItem({ quantity: 3, product: { quantity: 5, soldCount: 3 } })]),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isLeft()).toBe(true);
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });

  it('deve aceitar quando a quantidade pedida é exatamente o estoque disponível', async () => {
    mockCartRepository.getUserCart.mockResolvedValue(
      right([buildCartItem({ quantity: 2, product: { quantity: 5, soldCount: 3 } })]),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isRight()).toBe(true);
  });

  it('deve exigir CPF no modo session', async () => {
    mockCartRepository.findUserCpf.mockResolvedValue(right(null));

    const result = await sut.execute({ userId: 'buyer-1', mode: CheckoutMode.SESSION });

    expect(result.isLeft()).toBe(true);
    expect((result.value as BadRequestError).message).toContain('CPF');
  });

  it('não deve exigir CPF no modo intent', async () => {
    mockCartRepository.findUserCpf.mockResolvedValue(right(null));

    const result = await sut.execute({ userId: 'buyer-1', mode: CheckoutMode.INTENT });

    expect(result.isRight()).toBe(true);
    expect(mockPaymentProvider.createPaymentIntent).toHaveBeenCalled();
  });

  it('deve criar exatamente um grupo de pagamento para um carrinho com três itens', async () => {
    mockCartRepository.getUserCart.mockResolvedValue(
      right([
        buildCartItem({ productId: 'p1', product: { id: 'p1', sellerId: 's1' } }),
        buildCartItem({ productId: 'p2', product: { id: 'p2', sellerId: 's2' } }),
        buildCartItem({ productId: 'p3', product: { id: 'p3', sellerId: 's3' } }),
      ]),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isRight()).toBe(true);
    expect(mockCartRepository.reserveAndCreateOrder).toHaveBeenCalledTimes(3);
    expect(mockPaymentGroupRepository.create).toHaveBeenCalledTimes(1);
    expect(mockPaymentProvider.createPaymentSession).toHaveBeenCalledTimes(1);
  });

  it('deve somar o total de todos os itens no grupo', async () => {
    mockCartRepository.getUserCart.mockResolvedValue(
      right([
        buildCartItem({ productId: 'p1', quantity: 2, product: { id: 'p1', price: 10000 } }),
        buildCartItem({ productId: 'p2', quantity: 1, product: { id: 'p2', price: 5000 } }),
      ]),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect((result.value as { totalAmount: number }).totalAmount).toBe(25000);
    expect(mockPaymentGroupRepository.create.mock.calls[0][0].amount).toBe(25000);
  });

  it('deve limpar o carrinho somente depois de vincular o pagamento', async () => {
    await sut.execute({ userId: 'buyer-1' });

    expect(mockCartRepository.clear).toHaveBeenCalledWith(
      'buyer-1',
      expect.objectContaining({ $queryRaw: expect.any(Function) }),
    );
    expect(mockPaymentGroupRepository.attachPayment.mock.invocationCallOrder[0]).toBeLessThan(
      mockCartRepository.clear.mock.invocationCallOrder[0],
    );
  });

  it('deve manter as reservas quando a resposta da Stripe é ambígua', async () => {
    mockCartRepository.getUserCart.mockResolvedValue(
      right([
        buildCartItem({ productId: 'p1', product: { id: 'p1', sellerId: 's1' } }),
        buildCartItem({ productId: 'p2', product: { id: 'p2', sellerId: 's2' } }),
      ]),
    );
    mockCartRepository.reserveAndCreateOrder
      .mockResolvedValueOnce({ id: 'order-1' })
      .mockResolvedValueOnce({ id: 'order-2' });
    mockPaymentProvider.createPaymentSession.mockResolvedValue(
      left(new BadRequestError('stripe down')),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isLeft()).toBe(true);
    expect(mockCartRepository.restoreOrderReservation).not.toHaveBeenCalled();
    expect(mockPaymentGroupRepository.markTerminal).not.toHaveBeenCalled();
    expect(mockCartRepository.clear).not.toHaveBeenCalled();
  });

  it('does not reserve another order while the account has a pending attempt', async () => {
    mockPaymentGroupRepository.findLatestOpenForBuyer.mockResolvedValue(right({
      mode: CheckoutMode.SESSION,
      group: { status: 'PENDING' },
    }));

    const result = await sut.execute({ userId: 'buyer-1', mode: CheckoutMode.INTENT });

    expect(result.isLeft()).toBe(true);
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
    expect(mockPaymentProvider.createPaymentIntent).not.toHaveBeenCalled();
  });

  it('não tenta de novo um grupo pendente sem identidade Stripe persistida', async () => {
    mockPaymentGroupRepository.findByIdempotencyKey.mockResolvedValue(right({
      id: 'group-ambiguous', buyerId: 'buyer-1', amount: 10000, currency: 'brl', status: 'PENDING',
      stripePaymentIntentId: null, stripeSessionId: null, clientSecret: null, checkoutUrl: null,
      expiresAt: new Date(Date.now() + 60_000), orders: [],
    }));

    const result = await sut.execute({ userId: 'buyer-1', mode: CheckoutMode.SESSION });

    expect(result.isLeft()).toBe(true);
    expect(mockPaymentProvider.createPaymentSession).not.toHaveBeenCalled();
    expect(mockPaymentGroupRepository.create).not.toHaveBeenCalled();
  });

  it('deve cancelar o pagamento externo antes de compensar uma falha de finalização', async () => {
    mockPaymentGroupRepository.attachPayment.mockResolvedValue(
      left(new DatabaseError('attach failed')),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isLeft()).toBe(true);
    expect(mockPaymentProvider.cancelPendingPayment).toHaveBeenCalledWith({
      stripeSessionId: 'cs_1',
      idempotencyKey: 'group-cancel:group-1',
    });
    expect(mockCartRepository.restoreOrderReservation).toHaveBeenCalled();
    expect(mockPaymentGroupRepository.markTerminal).toHaveBeenCalled();
  });

  it('deve manter o grupo pendente quando o pagamento externo não pode ser cancelado', async () => {
    mockPaymentGroupRepository.attachPayment.mockResolvedValue(
      left(new DatabaseError('attach failed')),
    );
    mockPaymentProvider.cancelPendingPayment.mockResolvedValue(
      left(new DatabaseError('cancellation uncertain')),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isLeft()).toBe(true);
    expect(mockCartRepository.restoreOrderReservation).not.toHaveBeenCalled();
    expect(mockPaymentGroupRepository.markTerminal).not.toHaveBeenCalled();
  });

  it('deve devolver o grupo existente sem criar reservas quando a mesma chave de idempotência já tem um grupo pendente', async () => {
    mockPaymentGroupRepository.findByIdempotencyKey.mockResolvedValue(
      right({
        id: 'group-existing',
        buyerId: 'buyer-1',
        amount: 10000,
        currency: 'brl',
        status: 'PENDING',
        stripePaymentIntentId: null,
        stripeSessionId: 'cs_existing',
        clientSecret: null,
        checkoutUrl: 'https://checkout.stripe.com/cs_existing',
        expiresAt: new Date('2100-01-01T00:00:00.000Z'),
        orders: [
          {
            orderId: 'order-existing',
            transactionId: 'tx-1',
            amount: 10000,
            sellerId: 'seller-1',
            productId: 'product-1',
            productTitle: 'iPhone 15',
            quantity: 1,
          },
        ],
      }),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isRight()).toBe(true);
    expect((result.value as { paymentGroupId: string }).paymentGroupId).toBe('group-existing');
    expect(mockCartRepository.reserveAndCreateOrder).not.toHaveBeenCalled();
    expect(mockPaymentProvider.createPaymentSession).not.toHaveBeenCalled();
  });

  it('uses a new identity when the same cart is checked out after a prior group was paid', async () => {
    mockPaymentGroupRepository.findByIdempotencyKey.mockResolvedValue(right({
      id: 'group-paid', buyerId: 'buyer-1', amount: 10000, currency: 'brl', status: 'PAID',
      stripePaymentIntentId: 'pi_paid', stripeSessionId: null, clientSecret: null, checkoutUrl: null,
      expiresAt: new Date('2026-01-01T00:00:00.000Z'), orders: [],
    }));

    const result = await sut.execute({ userId: 'buyer-1', mode: CheckoutMode.SESSION });

    expect(result.isRight()).toBe(true);
    expect(mockPaymentGroupRepository.create).toHaveBeenCalledWith(
      expect.objectContaining({ idempotencyKey: expect.stringMatching(/^cart:buyer-1:session:[a-f0-9]{32}:[0-9a-f-]{36}$/) }),
      expect.anything(),
    );
    expect(mockCartRepository.reserveAndCreateOrder).toHaveBeenCalledTimes(1);
  });

  it('deve criar um novo grupo quando o grupo com a mesma chave já expirou', async () => {
    mockPaymentGroupRepository.findByIdempotencyKey.mockResolvedValue(
      right({
        id: 'group-old',
        buyerId: 'buyer-1',
        amount: 10000,
        currency: 'brl',
        status: 'PENDING',
        stripePaymentIntentId: null,
        stripeSessionId: 'cs_old',
        clientSecret: null,
        checkoutUrl: 'https://checkout.stripe.com/cs_old',
        expiresAt: new Date('2000-01-01T00:00:00.000Z'),
        orders: [],
      }),
    );

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isRight()).toBe(true);
    expect(mockPaymentGroupRepository.create).toHaveBeenCalled();
  });

  it('deve propagar o erro de estoque quando a reserva falha dentro da transação', async () => {
    mockPrisma.$transaction.mockRejectedValue(new Error('PRODUCT_UNAVAILABLE'));

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(BadRequestError);
    expect(mockPaymentProvider.createPaymentSession).not.toHaveBeenCalled();
  });

  it('deve devolver DatabaseError quando a transação falha por outro motivo', async () => {
    mockPrisma.$transaction.mockRejectedValue(new Error('connection reset'));

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });

  it('deve devolver o clientSecret no modo intent e nenhum checkoutUrl', async () => {
    const result = await sut.execute({ userId: 'buyer-1', mode: CheckoutMode.INTENT });

    const output = result.value as {
      paymentIntentClientSecret: string | null;
      checkoutUrl: string | null;
    };
    expect(output.paymentIntentClientSecret).toBe('pi_1_secret');
    expect(output.checkoutUrl).toBeNull();
  });

  it('deve devolver o checkoutUrl no modo session e nenhum clientSecret', async () => {
    const result = await sut.execute({ userId: 'buyer-1', mode: CheckoutMode.SESSION });

    const output = result.value as {
      paymentIntentClientSecret: string | null;
      checkoutUrl: string | null;
    };
    expect(output.checkoutUrl).toBe('https://checkout.stripe.com/cs_1');
    expect(output.paymentIntentClientSecret).toBeNull();
  });

  it('deve enviar uma linha por item do carrinho para a Stripe no modo session', async () => {
    mockCartRepository.getUserCart.mockResolvedValue(
      right([
        buildCartItem({ productId: 'p1', quantity: 2, product: { id: 'p1', title: 'A', price: 1000 } }),
        buildCartItem({ productId: 'p2', quantity: 1, product: { id: 'p2', title: 'B', price: 3000 } }),
      ]),
    );

    await sut.execute({ userId: 'buyer-1', mode: CheckoutMode.SESSION });

    const params = mockPaymentProvider.createPaymentSession.mock.calls[0][0];
    expect(params.lineItems).toEqual([
      { name: 'A', amount: 1000, quantity: 2 },
      { name: 'B', amount: 3000, quantity: 1 },
    ]);
    expect(params.paymentGroupId).toBe('group-1');
    expect(params.orderId).toBeUndefined();
  });

  it('deve propagar a falha quando a leitura do carrinho falha', async () => {
    mockCartRepository.getUserCart.mockResolvedValue(left(new DatabaseError('boom')));

    const result = await sut.execute({ userId: 'buyer-1' });

    expect(result.isLeft()).toBe(true);
    expect(result.value).toBeInstanceOf(DatabaseError);
  });
});
