import { CreateOrderUseCase } from './order.usecase';
import { PrismaOrderRepository } from '../repositories/order.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { prisma } from '../../../../test/setup-integration';
import { UserFactory, ProductFactory } from '../../../../test/factories';
import { isLeft, isRight } from '@/shared/core/either';
import { CreateOrderInput } from '../dtos/order.dto';

describe('CreateOrderUseCase Integration', () => {
  let sut: CreateOrderUseCase;
  let orderRepository: PrismaOrderRepository;
  let prismaService: PrismaService;
  let userFactory: UserFactory;
  let productFactory: ProductFactory;

  beforeEach(() => {
    prismaService = new PrismaService();
    orderRepository = new PrismaOrderRepository(prismaService);
    userFactory = new UserFactory(prisma);
    productFactory = new ProductFactory(prisma);
    sut = new CreateOrderUseCase(orderRepository, prismaService);
  });

  describe('Business Rules', () => {
    it('should create order with correct 10% platform fee split', async () => {
      // Arrange - Product price: R$100.00 (10000 cents)
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id, { price: 10000 });

      const input: CreateOrderInput = {
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: product.id,
        amount: 10000,
        platformFeePercent: 10,
      };

      // Act
      const result = await sut.execute(input);

      // Assert
      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        const order = result.right;
        expect(order.amount).toBe(10000);

        // Verify splits in database
        const dbOrder = await prisma.order.findUnique({
          where: { id: order.id },
        });

        expect(dbOrder?.platformFee).toBe(1000); // 10%
        expect(dbOrder?.sellerAmount).toBe(9000); // 90%
        expect(dbOrder?.platformFee + dbOrder?.sellerAmount).toBe(dbOrder?.amount);
      }
    });

    it('should handle fractional cents correctly', async () => {
      // Arrange - Product price: R$10.55 (1055 cents)
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id, { price: 1055 });

      const input: CreateOrderInput = {
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: product.id,
        amount: 1055,
        platformFeePercent: 10,
      };

      // Act
      const result = await sut.execute(input);

      // Assert
      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        const dbOrder = await prisma.order.findUnique({
          where: { id: result.right.id },
        });

        // Math.round(1055 * 0.10) = 106
        expect(dbOrder?.platformFee).toBe(106);
        expect(dbOrder?.sellerAmount).toBe(949); // 1055 - 106
        expect(dbOrder?.platformFee + dbOrder?.sellerAmount).toBe(dbOrder?.amount);
      }
    });

    it('should reject order if product does not exist', async () => {
      // Arrange
      const buyer = await userFactory.create();
      const seller = await userFactory.create();

      const input: CreateOrderInput = {
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: 'non-existent-id',
        amount: 10000,
        platformFeePercent: 10,
      };

      // Act
      const result = await sut.execute(input);

      // Assert
      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.left.code).toBe('NOT_FOUND');
        expect(result.left.message).toContain('Product');
      }
    });

    it('should reject order if product is already sold', async () => {
      // Arrange
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.createSold(seller.id);

      const input: CreateOrderInput = {
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: product.id,
        amount: product.price,
        platformFeePercent: 10,
      };

      // Act
      const result = await sut.execute(input);

      // Assert
      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.left.code).toBe('INVALID_ORDER_STATE');
        expect(result.left.message).toContain('already sold');
      }
    });

    it('should reject order if buyer is the seller', async () => {
      // Arrange
      const user = await userFactory.create();
      const product = await productFactory.create(user.id);

      const input: CreateOrderInput = {
        buyerId: user.id,
        sellerId: user.id,
        productId: product.id,
        amount: product.price,
        platformFeePercent: 10,
      };

      // Act
      const result = await sut.execute(input);

      // Assert
      expect(isLeft(result)).toBe(true);
      if (isLeft(result)) {
        expect(result.left.code).toBe('BAD_REQUEST');
        expect(result.left.message).toContain('Cannot buy your own product');
      }
    });

    it('should set order status to PENDING and escrow to HELD', async () => {
      // Arrange
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);

      const input: CreateOrderInput = {
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: product.id,
        amount: product.price,
        platformFeePercent: 10,
      };

      // Act
      const result = await sut.execute(input);

      // Assert
      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        const dbOrder = await prisma.order.findUnique({
          where: { id: result.right.id },
        });

        expect(dbOrder?.status).toBe('PENDING');
        expect(dbOrder?.escrowStatus).toBe('HELD');
      }
    });

    it('should mark product as SOLD after order creation', async () => {
      // Arrange
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id);

      expect(product.status).toBe('ACTIVE');

      const input: CreateOrderInput = {
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: product.id,
        amount: product.price,
        platformFeePercent: 10,
      };

      // Act
      const result = await sut.execute(input);

      // Assert
      expect(isRight(result)).toBe(true);

      const updatedProduct = await prisma.product.findUnique({
        where: { id: product.id },
      });

      expect(updatedProduct?.status).toBe('SOLD');
    });

    it('should create orders for different products', async () => {
      // Arrange
      const buyer = await userFactory.create();
      const seller1 = await userFactory.create();
      const seller2 = await userFactory.create();
      const product1 = await productFactory.create(seller1.id, { price: 5000 });
      const product2 = await productFactory.create(seller2.id, { price: 15000 });

      // Act
      const result1 = await sut.execute({
        buyerId: buyer.id,
        sellerId: seller1.id,
        productId: product1.id,
        amount: product1.price,
        platformFeePercent: 10,
      });

      const result2 = await sut.execute({
        buyerId: buyer.id,
        sellerId: seller2.id,
        productId: product2.id,
        amount: product2.price,
        platformFeePercent: 10,
      });

      // Assert
      expect(isRight(result1)).toBe(true);
      expect(isRight(result2)).toBe(true);

      const orders = await prisma.order.findMany({
        where: { buyerId: buyer.id },
      });

      expect(orders).toHaveLength(2);
      expect(orders[0].amount).toBe(5000);
      expect(orders[1].amount).toBe(15000);
    });
  });

  describe('Platform Fee Calculation Edge Cases', () => {
    it('should handle very small amounts (R$0.01)', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id, { price: 1 });

      const result = await sut.execute({
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: product.id,
        amount: 1,
        platformFeePercent: 10,
      });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        const dbOrder = await prisma.order.findUnique({
          where: { id: result.right.id },
        });

        // Math.round(1 * 0.10) = 0
        expect(dbOrder?.platformFee).toBe(0);
        expect(dbOrder?.sellerAmount).toBe(1);
      }
    });

    it('should handle large amounts (R$10,000.00)', async () => {
      const buyer = await userFactory.create();
      const seller = await userFactory.create();
      const product = await productFactory.create(seller.id, { price: 1000000 }); // R$10,000.00

      const result = await sut.execute({
        buyerId: buyer.id,
        sellerId: seller.id,
        productId: product.id,
        amount: 1000000,
        platformFeePercent: 10,
      });

      expect(isRight(result)).toBe(true);
      if (isRight(result)) {
        const dbOrder = await prisma.order.findUnique({
          where: { id: result.right.id },
        });

        expect(dbOrder?.platformFee).toBe(100000); // R$1,000.00
        expect(dbOrder?.sellerAmount).toBe(900000); // R$9,000.00
      }
    });
  });
});
