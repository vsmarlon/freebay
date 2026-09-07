import { prisma } from '../../../../../test/setup-integration';
import { UserFactory, ProductFactory } from '../../../../../test/factories';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { isLeft, isRight, left, right } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';
import { CartDatabaseRepository } from './cart-database.repository';

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
      return left(new BadRequestError((error as Error).message));
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

    expect(results.filter(isRight)).toHaveLength(1);
    expect(results.filter(isLeft)).toHaveLength(1);
    expect(await prisma.order.count({ where: { productId: product.id } })).toBe(1);
  });

  it('never oversells a multi-unit product under concurrent checkouts', async () => {
    const seller = await userFactory.create();
    const product = await productFactory.create(seller.id, { price: 5000, quantity: 5 });

    const buyers = await Promise.all(Array.from({ length: 5 }, () => userFactory.create()));
    const results = await Promise.all(
      buyers.map((buyer) => checkout(buyer.id, seller.id, product, 2)),
    );

    const succeeded = results.filter(isRight).length;
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
    expect(isRight(result)).toBe(true);

    const stored = await prisma.product.findUnique({ where: { id: product.id } });
    expect(stored?.soldCount).toBe(3);

    const order = await prisma.order.findFirst({ where: { productId: product.id } });
    expect(order?.quantity).toBe(3);
    expect(order?.amount).toBe(15000);
  });
});
