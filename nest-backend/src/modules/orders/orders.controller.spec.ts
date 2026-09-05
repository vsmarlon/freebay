import { Test, TestingModule } from '@nestjs/testing';
import { OrdersController } from './orders.controller';
import { OrderRepository } from './domain/repositories/order.repository';
import { CreateOrderUseCase } from './usecases/create-order.usecase';
import { ConfirmDeliveryUseCase } from './usecases/confirm-delivery.usecase';
import { MarkAsShippedUseCase } from './usecases/mark-as-shipped.usecase';
import { MarkAsDeliveredUseCase } from './usecases/mark-as-delivered.usecase';
import { CancelOrderUseCase } from './usecases/cancel-order.usecase';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { right, isLeft, Either } from '@/shared/core/either';
import { AppError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { AuthUser } from '@/shared/core/types';

describe('OrdersController', () => {
  let controller: OrdersController;
  let mockOrderRepository: { findById: jest.Mock; findProductForOrder: jest.Mock; findByBuyerId: jest.Mock; findBySellerId: jest.Mock };

  beforeEach(async () => {
    mockOrderRepository = {
      findById: jest.fn(),
      findProductForOrder: jest.fn(),
      findByBuyerId: jest.fn(),
      findBySellerId: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [OrdersController],
      providers: [
        { provide: OrderRepository, useValue: mockOrderRepository },
        { provide: CreateOrderUseCase, useValue: {} },
        { provide: ConfirmDeliveryUseCase, useValue: {} },
        { provide: MarkAsShippedUseCase, useValue: {} },
        { provide: MarkAsDeliveredUseCase, useValue: {} },
        { provide: CancelOrderUseCase, useValue: {} },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<OrdersController>(OrdersController);
  });

  describe('findOne (IDOR Security Check)', () => {
    const mockOrder = {
      id: 'order-123',
      buyerId: 'buyer-user-1',
      sellerId: 'seller-user-2',
      productId: 'prod-123',
      amount: 5000,
    };

    it('should allow the buyer to view their order', async () => {
      mockOrderRepository.findById.mockResolvedValue(right(mockOrder));
      const buyerUser: AuthUser = { userId: 'buyer-user-1', role: 'USER' };

      const result = await controller.findOne('order-123', buyerUser);

      expect((result as any).order).toEqual(mockOrder);
    });

    it('should allow the seller to view their order', async () => {
      mockOrderRepository.findById.mockResolvedValue(right(mockOrder));
      const sellerUser: AuthUser = { userId: 'seller-user-2', role: 'USER' };

      const result = await controller.findOne('order-123', sellerUser);

      expect((result as any).order).toEqual(mockOrder);
    });

    it('should allow an admin to view any order', async () => {
      mockOrderRepository.findById.mockResolvedValue(right(mockOrder));
      const adminUser: AuthUser = { userId: 'admin-user-99', role: 'ADMIN' };

      const result = await controller.findOne('order-123', adminUser);

      expect((result as any).order).toEqual(mockOrder);
    });

    it('should block an unrelated user with ForbiddenError (preventing IDOR)', async () => {
      mockOrderRepository.findById.mockResolvedValue(right(mockOrder));
      const attackerUser: AuthUser = { userId: 'stranger-user-3', role: 'USER' };

      const result = await controller.findOne('order-123', attackerUser);

      const eitherResult = result as unknown as Either<AppError, unknown>;
      expect(isLeft(eitherResult)).toBe(true);
      if (isLeft(eitherResult)) {
        expect(eitherResult.value).toBeInstanceOf(ForbiddenError);
      }
    });

    it('should return NotFoundError when order does not exist', async () => {
      mockOrderRepository.findById.mockResolvedValue(right(null));
      const anyUser: AuthUser = { userId: 'user-1', role: 'USER' };

      const result = await controller.findOne('non-existent-order', anyUser);

      const eitherResult = result as unknown as Either<AppError, unknown>;
      expect(isLeft(eitherResult)).toBe(true);
      if (isLeft(eitherResult)) {
        expect(eitherResult.value).toBeInstanceOf(NotFoundError);
      }
    });
  });
});
