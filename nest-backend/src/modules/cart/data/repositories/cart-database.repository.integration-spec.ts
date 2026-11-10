import { prisma } from '../../../../../test/setup-integration';
import { UserFactory, ProductFactory } from '../../../../../test/factories';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { left, right } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';
import { CartDatabaseRepository } from './cart-database.repository';
import { PaymentGroupDatabaseRepository } from '@/modules/payments/data/repositories/payment-group-database.repository';
import { CheckoutCartReservation } from '../../usecases/checkout-cart/checkout-cart-reservation';
import { Test } from '@nestjs/testing';
import { CheckoutCartUseCase } from '../../usecases/checkout-cart.usecase';
import { StripeProvider } from '@/modules/payments/providers/stripe-provider';
import { UserDatabaseRepository } from '@/modules/users';
import { PaymentProviderError } from '@/shared/core/errors';
import { GetCheckoutRecoveryUseCase } from '../../usecases/get-checkout-recovery.usecase';
import { CheckoutMode } from '../../dtos/cart.dto';

describe('CartDatabaseRepository reservations Integration', () => {
  let sut: CartDatabaseRepository;
  let userFactory: UserFactory;
  let productFactory: ProductFactory;

  beforeAll(() => {
    sut = new CartDatabaseRepository(prisma as PrismaService);
    userFactory = new UserFactory(prisma);
    productFactory = new ProductFactory(prisma);
  });

  async function checkout(
    buyerId: string,
    sellerId: string,
    product: { id: string; price: number },
    quantity: number,
  ) {
    const amount = product.price * quantity;
    const platformFee = Math.round(amount * 0.1);
    try {
      const order = await prisma.$transaction((tx) =>
        sut.reserveAndCreateOrder(
          {
            userId: buyerId,
            sellerId,
            productId: product.id,
            quantity,
            amount,
            platformFee,
            sellerAmount: amount - platformFee,
          },
          tx,
        ),
      );
      return right(order);
    } catch (error) {
      return left(new BadRequestError(error instanceof Error ? error.message : String(error)));
    }
  }

  it('lets only one of two concurrent buyers reserve a single-unit product', async () => {
    const seller = await userFactory.create();
    const buyerA = await userFactory.create();
    const buyerB = await userFactory.create();
    const product = await productFactory.create(seller.id, { price: 10000, quantity: 1 });

    const results = await Promise.all([
      checkout(buyerA.id, seller.id, product, 1),
      checkout(buyerB.id, seller.id, product, 1),
    ]);

    expect(results.filter((r) => r.isRight())).toHaveLength(1);
    expect(results.filter((r) => r.isLeft())).toHaveLength(1);
    expect(await prisma.order.count({ where: { productId: product.id } })).toBe(1);
    const stored = await prisma.product.findUniqueOrThrow({ where: { id: product.id } });
    expect(stored.soldCount).toBe(0);
    expect(stored.status).toBe('PAUSED');
    const order = await prisma.order.findFirstOrThrow({ where: { productId: product.id } });
    expect(order.quantity).toBe(1);
    expect(order.amount).toBe(10000);
    expect(order.platformFee).toBe(1000);
    expect(order.sellerAmount).toBe(9000);
  });

  it('never oversells a multi-unit product under concurrent checkouts', async () => {
    const seller = await userFactory.create();
    const product = await productFactory.create(seller.id, { price: 5000, quantity: 5 });

    const buyers = await Promise.all(Array.from({ length: 5 }, () => userFactory.create()));
    const results = await Promise.all(
      buyers.map((buyer) => checkout(buyer.id, seller.id, product, 2)),
    );

    const succeeded = results.filter((r) => r.isRight()).length;
    const stored = await prisma.product.findUnique({ where: { id: product.id } });

    expect(succeeded).toBe(2);
    expect(stored?.soldCount).toBe(4);
    expect(stored!.soldCount).toBeLessThanOrEqual(stored!.quantity);
  });

  it('reserves the ordered quantity, not a single unit', async () => {
    const seller = await userFactory.create();
    const buyer = await userFactory.create();
    const product = await productFactory.create(seller.id, { price: 5000, quantity: 10 });

    const result = await checkout(buyer.id, seller.id, product, 3);
    expect(result.isRight()).toBe(true);

    const stored = await prisma.product.findUnique({ where: { id: product.id } });
    expect(stored?.soldCount).toBe(3);

    const order = await prisma.order.findFirst({ where: { productId: product.id } });
    expect(order?.quantity).toBe(3);
    expect(order?.amount).toBe(15000);
  });

  it('serializes concurrent session and intent reservations for one buyer', async () => {
    const buyer = await userFactory.create();
    const seller = await userFactory.create();
    const product = await productFactory.create(seller.id, { price: 10000, quantity: 2 });
    const module = await Test.createTestingModule({
      providers: [
        CheckoutCartReservation,
        { provide: PrismaService, useValue: prisma },
        { provide: CartDatabaseRepository, useValue: sut },
        PaymentGroupDatabaseRepository,
      ],
    }).compile();
    const reservation = module.get(CheckoutCartReservation);
    const planned = {
      userId: buyer.id,
      sellerId: seller.id,
      productId: product.id,
      quantity: 1,
      amount: 10000,
      platformFee: 1000,
      sellerAmount: 9000,
      productTitle: product.title,
    };
    const results = await Promise.allSettled([
      reservation.reserve(buyer.id, `cart:${buyer.id}:session:session-test`, 10000, [planned]),
      reservation.reserve(buyer.id, `cart:${buyer.id}:intent:intent-test`, 10000, [planned]),
    ]);

    expect(results.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    const rejected = results.find((result) => result.status === 'rejected');
    expect(rejected?.status === 'rejected' && rejected.reason).toBeInstanceOf(PaymentProviderError);
    expect(await prisma.paymentGroup.count({ where: { buyerId: buyer.id } })).toBe(1);
    expect(await prisma.order.count({ where: { buyerId: buyer.id } })).toBe(1);
    const stored = await prisma.product.findUniqueOrThrow({ where: { id: product.id } });
    expect(stored.soldCount).toBe(1);
    const order = await prisma.order.findFirstOrThrow({ where: { buyerId: buyer.id } });
    expect(order.quantity).toBe(1);
    expect(order.amount).toBe(10000);
    expect(order.platformFee).toBe(1000);
    expect(order.sellerAmount).toBe(9000);
  });

  it('keeps one real checkout attempt across concurrent session and intent calls', async () => {
    const buyer = await userFactory.create();
    const seller = await userFactory.create();
    const product = await productFactory.create(seller.id, { price: 10000, quantity: 2 });
    await prisma.cartItem.create({ data: { userId: buyer.id, productId: product.id, quantity: 1 } });
    const calls = { session: 0, intent: 0 };
    const getUserCart = sut.getUserCart.bind(sut);
    let cartReads = 0;
    let releaseCartReads!: () => void;
    const bothCartReads = new Promise<void>((resolve) => { releaseCartReads = resolve; });
    const concurrentCartRepository = new Proxy(sut, {
      get(target, property, receiver) {
        if (property === 'findUserCpf') return async () => right('52998224725');
        if (property === 'getUserCart') {
          return async (userId: string) => {
            const result = await getUserCart(userId);
            cartReads += 1;
            if (cartReads === 2) releaseCartReads();
            await bothCartReads;
            return result;
          };
        }
        return Reflect.get(target, property, receiver);
      },
    });
    const provider = {
      createPaymentSession: async (params: Parameters<StripeProvider['createPaymentSession']>[0]) => {
        calls.session += 1;
        const stripeSessionId = `cs_test_${params.paymentGroupId}`;
        return right({ stripeSessionId, checkoutUrl: 'https://checkout.stripe.com/test', expiresAt: params.expiresAt! });
      },
      retrievePaymentSession: async (stripeSessionId: string) => {
        const groupId = stripeSessionId.replace('cs_test_', '');
        const group = await prisma.paymentGroup.findUniqueOrThrow({ where: { id: groupId } });
        return right({
          stripeSessionId, checkoutUrl: 'https://checkout.stripe.com/test', status: 'open' as const,
          mode: 'payment' as const, paymentStatus: 'unpaid' as const, amountTotal: group.amount,
          currency: 'brl', orderId: null, paymentGroupId: groupId, buyerId: buyer.id,
          idempotencyKey: `group-session:${groupId}`, expiresAt: group.expiresAt,
        });
      },
      createPaymentIntent: async () => {
        calls.intent += 1;
        return right({ paymentIntentId: 'pi_test', clientSecret: 'pi_test_secret' });
      },
      cancelPendingPayment: async () => right(undefined),
    };
    const paymentGroupsModule = await Test.createTestingModule({
      providers: [
        PaymentGroupDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    const paymentGroups = paymentGroupsModule.get(PaymentGroupDatabaseRepository);
    const checkoutModule = await Test.createTestingModule({
      providers: [
        CheckoutCartUseCase,
        { provide: PrismaService, useValue: prisma },
        { provide: CartDatabaseRepository, useValue: concurrentCartRepository },
        { provide: PaymentGroupDatabaseRepository, useValue: paymentGroups },
        { provide: UserDatabaseRepository, useValue: { findPaymentInfo: async () => right({ displayName: 'Buyer', email: 'buyer@example.com', cpf: null }) } },
        { provide: StripeProvider, useValue: provider },
      ],
    }).compile();
    const checkoutUseCase = checkoutModule.get(CheckoutCartUseCase);

    const results = await Promise.all([
      checkoutUseCase.execute({ userId: buyer.id, mode: CheckoutMode.SESSION }),
      checkoutUseCase.execute({ userId: buyer.id, mode: CheckoutMode.INTENT }),
    ]);

    expect(results.filter((result) => result.isRight())).toHaveLength(1);
    const loser = results.find((result) => result.isLeft());
    expect(loser?.isLeft() && loser.value).toBeInstanceOf(PaymentProviderError);
    expect(calls.session + calls.intent).toBe(1);
    expect(await prisma.paymentGroup.count({ where: { buyerId: buyer.id } })).toBe(1);
    expect(await prisma.order.count({ where: { buyerId: buyer.id } })).toBe(1);
    const stored = await prisma.product.findUniqueOrThrow({ where: { id: product.id } });
    expect(stored.soldCount).toBe(1);
    const order = await prisma.order.findFirstOrThrow({ where: { buyerId: buyer.id } });
    expect(order.amount).toBe(10000);
    expect(order.platformFee).toBe(1000);
    expect(order.sellerAmount).toBe(9000);
    const recoveryModule = await Test.createTestingModule({
      providers: [GetCheckoutRecoveryUseCase, { provide: PaymentGroupDatabaseRepository, useValue: paymentGroups }],
    }).compile();
    const recovery = await recoveryModule.get(GetCheckoutRecoveryUseCase).execute({ userId: buyer.id, mode: CheckoutMode.INTENT });
    expect(recovery.isRight()).toBe(true);
    expect(recovery.value).toMatchObject({ status: 'CHECKING', paymentGroupId: expect.any(String), totalAmount: 10000 });
  });
});
