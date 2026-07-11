import { CreatePixPaymentUseCase } from './create-pix-payment.usecase';
import { PrismaOrderRepository } from '../../orders/repositories/order.repository';
import { UserDatabaseRepository } from '../../auth/data/repositories/user-database.repository';
import { AbacatePayProvider } from '../providers/abacatepay.provider';
import { prisma } from '../../../../test/setup-integration';
import { UserFactory, ProductFactory } from '../../../../test/factories';
import { isLeft } from '@/shared/core/either';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

const mockAbacatePay = {
  createPixCharge: jest.fn(),
  verifyWebhook: jest.fn(),
} as unknown as AbacatePayProvider;

describe('CreatePixPaymentUseCase Integration', () => {
  let sut: CreatePixPaymentUseCase;
  let orderRepository: PrismaOrderRepository;
  let userRepository: UserDatabaseRepository;
  let userFactory: UserFactory;
  let productFactory: ProductFactory;

  beforeEach(() => {
    orderRepository = new PrismaOrderRepository(prisma as PrismaService);
    userRepository = new UserDatabaseRepository(prisma as PrismaService);
    userFactory = new UserFactory(prisma);
    productFactory = new ProductFactory(prisma);
    sut = new CreatePixPaymentUseCase(
      orderRepository,
      userRepository,
      prisma as PrismaService,
      mockAbacatePay,
    );
    jest.clearAllMocks();
  });

  it('should return error if order not found', async () => {
    const result = await sut.execute({
      orderId: 'nonexistent',
      userId: 'user-1',
      customerName: 'Test',
      customerTaxId: '12345678901',
      customerEmail: 'test@test.com',
    });
    expect(isLeft(result)).toBe(true);
    if (isLeft(result)) expect(result.value.code).toBe('NOT_FOUND');
  });

  it('should return error if user does not own the order', async () => {
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
      customerName: 'Test',
      customerTaxId: '12345678901',
      customerEmail: 'test@test.com',
    });
    expect(isLeft(result)).toBe(true);
    if (isLeft(result)) expect(result.value.code).toBe('BAD_REQUEST');
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
      customerName: 'Test',
      customerEmail: 'test@test.com',
    });
    expect(isLeft(result)).toBe(true);
    if (isLeft(result)) expect(result.value.code).toBe('BAD_REQUEST');
  });
});
