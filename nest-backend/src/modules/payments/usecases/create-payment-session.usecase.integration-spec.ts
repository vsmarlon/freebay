import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { CreatePaymentSessionUseCase } from './create-payment-session.usecase';
import { OrderDatabaseRepository } from '../../orders/data/repositories/order-database.repository';
import { UserDatabaseRepository } from '@/modules/users';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { StripeProvider } from '../providers/stripe-provider';
import { prisma } from '../../../../test/setup-integration';
import { UserFactory, ProductFactory } from '../../../../test/factories';
;
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { right } from '@/shared/core/either';
import { CpfProtectionService } from '@/shared/utils/cpf-protection.service';
import { PaymentSessionSnapshot } from '../types/payment-provider.types';

const mockPaymentProvider = {
  createPaymentSession: jest.fn(),
  verifyWebhook: jest.fn(),
  constructWebhookEvent: jest.fn(),
  retrievePaymentSession: jest.fn(),
};

describe('CreatePaymentSessionUseCase Integration', () => {
  let sut: CreatePaymentSessionUseCase;
  let userFactory: UserFactory;
  let productFactory: ProductFactory;
  let cpfProtection: CpfProtectionService;

  beforeEach(async () => {
    userFactory = new UserFactory(prisma);
    productFactory = new ProductFactory(prisma);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePaymentSessionUseCase,
        OrderDatabaseRepository,
        UserDatabaseRepository,
        TransactionDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
        { provide: ConfigService, useValue: {
          get: (key: string) => key === 'CPF_ENCRYPTION_KEY'
            ? Buffer.alloc(32, 1).toString('base64')
            : key === 'CPF_HMAC_KEY'
              ? Buffer.alloc(32, 2).toString('base64')
              : undefined,
        } },
        CpfProtectionService,
        { provide: StripeProvider, useValue: mockPaymentProvider },
      ],
    }).compile();

    sut = module.get(CreatePaymentSessionUseCase);
    cpfProtection = module.get(CpfProtectionService);

    jest.clearAllMocks();
    mockPaymentProvider.createPaymentSession = jest.fn().mockResolvedValue(
      right({
        stripeSessionId: 'cs_test_integration',
        checkoutUrl: 'https://checkout.stripe.com/pay/cs_test_integration',
        expiresAt: new Date(),
      }),
    );
    mockPaymentProvider.retrievePaymentSession = jest.fn().mockResolvedValue(right({
      stripeSessionId: 'cs_test_integration', checkoutUrl: 'https://checkout.stripe.com/pay/cs_test_integration',
      status: 'open', mode: 'payment', paymentStatus: 'unpaid', amountTotal: 10000, currency: 'brl',
      orderId: null, paymentGroupId: null, buyerId: null, idempotencyKey: null, expiresAt: new Date(),
    } satisfies PaymentSessionSnapshot));
  });

  it('returns error if order not found', async () => {
    const result = await sut.execute({
      orderId: 'nonexistent',
      userId: 'user-1',
    });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.code).toBe('NOT_FOUND');
  });

  it('returns error if user does not own the order', async () => {
    const buyer = await userFactory.create();
    const seller = await userFactory.create();
    const product = await productFactory.create(seller.id);

    const order = await prisma.order.create({
      data: {
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: product.id,
        amount: 10000,
        platformFee: 1000,
        sellerAmount: 9000,
        status: 'PENDING',
        escrowStatus: 'HELD',
      },
    });

    const result = await sut.execute({
      orderId: order.id,
      userId: 'stranger',
    });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.code).toBe('BAD_REQUEST');
  });

  it('creates payment session for valid order with CPF', async () => {
    const buyer = await userFactory.create();
    const protectedCpf = cpfProtection.protect('52998224725');
    await prisma.user.update({ where: { id: buyer.id }, data: protectedCpf });
    const seller = await userFactory.create();
    const product = await productFactory.create(seller.id);
    const order = await prisma.order.create({
      data: {
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: product.id,
        amount: 10000,
        platformFee: 1000,
        sellerAmount: 9000,
        status: 'PENDING',
        escrowStatus: 'HELD',
      },
    });

    mockPaymentProvider.retrievePaymentSession.mockResolvedValue(right({
      stripeSessionId: 'cs_test_integration', checkoutUrl: 'https://checkout.stripe.com/pay/cs_test_integration',
      status: 'open', mode: 'payment', paymentStatus: 'unpaid', amountTotal: order.amount, currency: 'brl',
      orderId: order.id, paymentGroupId: null, buyerId: buyer.id,
      idempotencyKey: `session:${order.id}`, expiresAt: new Date(),
    } satisfies PaymentSessionSnapshot));

    const result = await sut.execute({
      orderId: order.id,
      userId: buyer.id,
    });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.stripeSessionId).toBe('cs_test_integration');
      expect(result.value.checkoutUrl).toBe('https://checkout.stripe.com/pay/cs_test_integration');
    }
    expect(mockPaymentProvider.createPaymentSession).toHaveBeenCalled();
  });

  it('keeps a durable unresolved attempt after local attach failure and never creates another Session on aged retry', async () => {
    const buyer = await userFactory.create();
    await prisma.user.update({
      where: { id: buyer.id },
      data: cpfProtection.protect('52998224725'),
    });
    const seller = await userFactory.create();
    const product = await productFactory.create(seller.id);
    const order = await prisma.order.create({
      data: {
        buyerId: buyer.id, sellerId: seller.id, productId: product.id,
        amount: 10000, platformFee: 1000, sellerAmount: 9000,
        status: 'PENDING', escrowStatus: 'HELD',
      },
    });
    mockPaymentProvider.retrievePaymentSession.mockResolvedValue(right({
      stripeSessionId: 'cs_test_integration', checkoutUrl: 'https://checkout.stripe.com/pay/cs_test_integration',
      status: 'open', mode: 'payment', paymentStatus: 'unpaid', amountTotal: order.amount, currency: 'brl',
      orderId: order.id, paymentGroupId: null, buyerId: buyer.id,
      idempotencyKey: `session:${order.id}`, expiresAt: new Date(),
    } satisfies PaymentSessionSnapshot));
    const attachFailure = jest.spyOn(prisma.transaction, 'updateMany')
      .mockRejectedValueOnce(new Error('local write unavailable'));

    const first = await sut.execute({ orderId: order.id, userId: buyer.id });
    attachFailure.mockRestore();
    await prisma.transaction.update({
      where: { orderId: order.id },
      data: { createdAt: new Date(Date.now() - 25 * 60 * 60 * 1000) },
    });
    const attempt = await prisma.transaction.findUnique({ where: { orderId: order.id } });
    const retry = await sut.execute({ orderId: order.id, userId: buyer.id });

    expect(first.isLeft()).toBe(true);
    expect(attempt?.externalId).toBeNull();
    expect(attempt?.idempotencyKey).toBe(`session:${order.id}`);
    expect(retry.isLeft()).toBe(true);
    expect(mockPaymentProvider.createPaymentSession).toHaveBeenCalledTimes(1);
  });

  it('returns error if user has no CPF', async () => {
    const buyer = await userFactory.create({ cpf: null });
    const seller = await userFactory.create();
    const product = await productFactory.create(seller.id);
    const order = await prisma.order.create({
      data: {
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: product.id,
        amount: 10000,
        platformFee: 1000,
        sellerAmount: 9000,
        status: 'PENDING',
        escrowStatus: 'HELD',
      },
    });

    const result = await sut.execute({
      orderId: order.id,
      userId: buyer.id,
    });
    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value.code).toBe('BAD_REQUEST');
  });
});
