import { prisma } from '../../../../../test/setup-integration';
import { UserFactory, ProductFactory } from '../../../../../test/factories';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CartDatabaseRepository } from '@/modules/cart/data/repositories/cart-database.repository';
import { ProductDatabaseRepository } from './product-database.repository';

describe('Product inventory parity Integration', () => {
  let products: ProductDatabaseRepository;
  let cart: CartDatabaseRepository;
  let userFactory: UserFactory;
  let productFactory: ProductFactory;

  beforeAll(() => {
    products = new ProductDatabaseRepository(prisma as PrismaService);
    cart = new CartDatabaseRepository(prisma as PrismaService);
    userFactory = new UserFactory(prisma);
    productFactory = new ProductFactory(prisma);
  });

  async function reserve(quantity: number, stock: number) {
    const seller = await userFactory.create();
    const buyer = await userFactory.create();
    const product = await productFactory.create(seller.id, { price: 5000, quantity: stock });
    const amount = 5000 * quantity;

    await prisma.$transaction((tx) =>
      cart.reserveAndCreateOrder(
        {
          userId: buyer.id,
          sellerId: seller.id,
          productId: product.id,
          quantity,
          amount,
          platformFee: Math.round(amount * 0.1),
          sellerAmount: amount - Math.round(amount * 0.1),
        },
        tx,
      ),
    );

    return product;
  }

  it('does not consume stock a second time when the payment settles', async () => {
    const product = await reserve(3, 10);

    await products.updateInventoryOnSale(product.id);

    const stored = await prisma.product.findUnique({ where: { id: product.id } });
    expect(stored?.soldCount).toBe(3);
  });

  it('marks a product SOLD once the reservation exhausts its stock', async () => {
    const product = await reserve(4, 4);

    await products.updateInventoryOnSale(product.id);

    const stored = await prisma.product.findUnique({ where: { id: product.id } });
    expect(stored?.soldCount).toBe(4);
    expect(stored?.status).toBe('SOLD');
  });

  it('restores the full ordered quantity when the session expires', async () => {
    const product = await reserve(3, 10);

    await products.restoreInventoryOnExpiry(product.id, 3);

    const stored = await prisma.product.findUnique({ where: { id: product.id } });
    expect(stored?.soldCount).toBe(0);
    expect(stored?.status).toBe('ACTIVE');
  });

  it('never drives soldCount negative when expiry runs twice', async () => {
    const product = await reserve(2, 10);

    await products.restoreInventoryOnExpiry(product.id, 2);
    await products.restoreInventoryOnExpiry(product.id, 2);

    const stored = await prisma.product.findUnique({ where: { id: product.id } });
    expect(stored?.soldCount).toBe(0);
  });
});
