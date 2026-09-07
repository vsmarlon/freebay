import { Test, TestingModule } from '@nestjs/testing';
import { CreatePaymentSessionUseCase } from './create-payment-session.usecase';
import { PrismaOrderRepository } from '../../orders/data/repositories/order-database.repository';
import { UserDatabaseRepository } from '../../auth/data/repositories/user-database.repository';
import { TransactionDatabaseRepository } from '../data/repositories/transaction-database.repository';
import { StripeProvider } from '../providers/stripe-provider';
import { prisma } from '../../../../test/setup-integration';
import { UserFactory, ProductFactory } from '../../../../test/factories';
import { isLeft } from '@/shared/core/either';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { right } from '@/shared/core/either';

const mockPaymentProvider = {
  createPaymentSession: jest.fn(),
  verifyWebhook: jest.fn(),
  constructWebhookEvent: jest.fn(),
};

describe('CreatePaymentSessionUseCase Integration', () => {
  let sut: CreatePaymentSessionUseCase;
  let userFactory: UserFactory;
  let productFactory: ProductFactory;

  beforeEach(async () => {
    userFactory = new UserFactory(prisma);
    productFactory = new ProductFactory(prisma);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreatePaymentSessionUseCase,
        PrismaOrderRepository,
        UserDatabaseRepository,
        TransactionDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
        { provide: StripeProvider, useValue: mockPaymentProvider },
      ],
    }).compile();

    sut = module.get(CreatePaymentSessionUseCase);

    jest.clearAllMocks();
    mockPaymentProvider.createPaymentSession = jest.fn().mockResolvedValue(
      right({
        stripeSessionId: 'cs_test_integration',
        checkoutUrl: 'https://checkout.stripe.com/pay/cs_test_integration',
        expiresAt: new Date(),
      }),
    );
  });

  it('should return error if order not found', async () => {
    const result = await sut.execute({
      orderId: 'nonexistent',
      userId: 'user-1',
    });
    expect(isLeft(result)).toBe(true);
    if (isLeft(result)) expect(result.value.code).toBe('NOT_FOUND');
  });

  it('should return error if user does not own the order', async () => {
    const buyer = await userFactory.create();
    const seller = await userFactory.create();
    const product = await productFactory.create(seller.id);

    // Update buyer CPF for the payment info lookup
    await prisma.user.update({
      where: { id: buyer.id },
      data: { cpf: '12345678901' },
    });

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
    expect(isLeft(result)).toBe(true);
    if (isLeft(result)) expect(result.value.code).toBe('BAD_REQUEST');
  });

  it('should create payment session for valid order with CPF', async () => {
    const buyer = await userFactory.create({ cpf: '12345678901' });
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

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.stripeSessionId).toBe('cs_test_integration');
      expect(result.value.checkoutUrl).toBe('https://checkout.stripe.com/pay/cs_test_integration');
    }
    expect(mockPaymentProvider.createPaymentSession).toHaveBeenCalled();
  });

  it('should return error if user has no CPF', async () => {
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
    expect(isLeft(result)).toBe(true);
    if (isLeft(result)) expect(result.value.code).toBe('BAD_REQUEST');
  });
});
