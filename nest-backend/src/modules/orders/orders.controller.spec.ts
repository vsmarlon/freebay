import { Test, TestingModule } from '@nestjs/testing';
import { OrdersController } from './orders.controller';
import { PrismaOrderRepository } from './data/repositories/order-database.repository';
import { CreateOrderUseCase } from './usecases/create-order.usecase';
import { ConfirmDeliveryUseCase } from './usecases/confirm-delivery.usecase';
import { MarkAsShippedUseCase } from './usecases/mark-as-shipped.usecase';
import { MarkAsDeliveredUseCase } from './usecases/mark-as-delivered.usecase';
import { CancelOrderUseCase } from './usecases/cancel-order.usecase';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { right, left, Left } from '@/shared/core/either';
import { BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { AuthUser } from '@/shared/core/types';
import { IncomingMessage, request as httpRequest } from 'http';
import { AllExceptionsFilter } from '@/shared/http/exception-filter';
import { EitherInterceptor } from '@/shared/http/response.interceptor';
import { TransformInterceptor } from '@/shared/http/transform.interceptor';
import { createValidationPipe } from '@/shared/http/validation-pipe.factory';
import { encodeCursor } from '@/shared/core/pagination';
import { SALES_ORDER_STATUSES } from './types/order.types';
import { SalesOrdersQueryDTO } from './dtos/order.dto';

describe('OrdersController', () => {
  let controller: OrdersController;
  let mockOrderRepository: { findById: jest.Mock; findProductForOrder: jest.Mock; findByBuyerId: jest.Mock; findBySellerId: jest.Mock; findSellerSales: jest.Mock };

  beforeEach(async () => {
    mockOrderRepository = {
      findById: jest.fn(),
      findProductForOrder: jest.fn(),
      findByBuyerId: jest.fn(),
      findBySellerId: jest.fn(),
      findSellerSales: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [OrdersController],
      providers: [
        { provide: PrismaOrderRepository, useValue: mockOrderRepository },
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

    it('allows the buyer to view their order', async () => {
      mockOrderRepository.findById.mockResolvedValue(right(mockOrder));
      const buyerUser: AuthUser = { userId: 'buyer-user-1', role: 'USER' };

      const result = await controller.findOne('order-123', buyerUser);

      expect(result).toEqual({ order: mockOrder });
    });

    it('allows the seller to view their order', async () => {
      mockOrderRepository.findById.mockResolvedValue(right(mockOrder));
      const sellerUser: AuthUser = { userId: 'seller-user-2', role: 'USER' };

      const result = await controller.findOne('order-123', sellerUser);

      expect(result).toEqual({ order: mockOrder });
    });

    it('allows an admin to view any order', async () => {
      mockOrderRepository.findById.mockResolvedValue(right(mockOrder));
      const adminUser: AuthUser = { userId: 'admin-user-99', role: 'ADMIN' };

      const result = await controller.findOne('order-123', adminUser);

      expect(result).toEqual({ order: mockOrder });
    });

    it('blocks an unrelated user with ForbiddenError (preventing IDOR)', async () => {
      mockOrderRepository.findById.mockResolvedValue(right(mockOrder));
      const attackerUser: AuthUser = { userId: 'stranger-user-3', role: 'USER' };

      const result = await controller.findOne('order-123', attackerUser);

      expect(result).toBeInstanceOf(Left);
      if (result instanceof Left) {
        expect(result.value).toBeInstanceOf(ForbiddenError);
      }
    });

    it('returns NotFoundError when order does not exist', async () => {
      mockOrderRepository.findById.mockResolvedValue(right(null));
      const anyUser: AuthUser = { userId: 'user-1', role: 'USER' };

      const result = await controller.findOne('non-existent-order', anyUser);

      expect(result).toBeInstanceOf(Left);
      if (result instanceof Left) {
        expect(result.value).toBeInstanceOf(NotFoundError);
      }
    });
  });

  describe('getMySales cursor contract', () => {
    const query = (values: Partial<SalesOrdersQueryDTO> = {}) => ({
      limit: 2,
      ...values,
    });

    it.each([...SALES_ORDER_STATUSES])(
      'ValidationPipe accepts status %s',
      async (status) => {
        const result = await createValidationPipe().transform(
          { status },
          { type: 'query', metatype: SalesOrdersQueryDTO },
        );

        expect(result).toBeInstanceOf(SalesOrdersQueryDTO);
        expect(result.status).toBe(status);
      },
    );

    it('ValidationPipe accepts an absent status', async () => {
      const result = await createValidationPipe().transform(
        {},
        { type: 'query', metatype: SalesOrdersQueryDTO },
      );

      expect(result.status).toBeUndefined();
    });

    it.each([
      ['invalid status', { status: 'UNKNOWN' }],
      ['zero limit', { limit: 0 }],
      ['oversized limit', { limit: 51 }],
    ])('ValidationPipe rejects %s', async (_name, input) => {
      await expect(
        createValidationPipe().transform(input, {
          type: 'query',
          metatype: SalesOrdersQueryDTO,
        }),
      ).rejects.toThrow();
    });

    it('scopes the repository call to the authenticated seller and selected status', async () => {
      mockOrderRepository.findSellerSales.mockResolvedValue(right({
        items: [],
        hasMore: false,
        nextCursor: null,
      }));

      await controller.getMySales('seller-1', query({ status: 'SHIPPED' }));

      expect(mockOrderRepository.findSellerSales).toHaveBeenCalledWith(
        'seller-1',
        { limit: 2 },
        'SHIPPED',
        null,
      );
    });

    it.each([
      ['malformed cursor', 'not-a-cursor'],
      ['wrong scope', encodeCursor({
        scope: 'purchases', sellerId: 'seller-1', status: 'ALL',
        createdAt: '2026-09-12T00:00:00.000Z', id: 'order-1',
      })],
      ['wrong seller', encodeCursor({
        scope: 'seller-sales', sellerId: 'seller-2', status: 'ALL',
        createdAt: '2026-09-12T00:00:00.000Z', id: 'order-1',
      })],
      ['wrong status', encodeCursor({
        scope: 'seller-sales', sellerId: 'seller-1', status: 'SHIPPED',
        createdAt: '2026-09-12T00:00:00.000Z', id: 'order-1',
      })],
      ['malformed cursor shape', encodeCursor({
        scope: 'seller-sales', sellerId: 'seller-1', status: 'ALL', id: 'order-1',
      })],
    ])('rejects %s without restarting at page one', async (_name, cursor) => {
      const result = await controller.getMySales('seller-1', query({ cursor }));

      expect(result).toBeInstanceOf(Left);
      expect(mockOrderRepository.findSellerSales).not.toHaveBeenCalled();
    });
  });
});

describe('OrdersController create HTTP contract', () => {
  let app: ReturnType<TestingModule['createNestApplication']>;
  let createOrder: jest.Mock;

  const post = async (body: object): Promise<{ statusCode: number; body: string }> => {
    const address = app.getHttpServer().address();
    if (address === null || typeof address === 'string') {
      throw new Error('Test server did not bind to a port');
    }
    return new Promise((resolve, reject) => {
      const request = httpRequest(
        {
          hostname: '127.0.0.1',
          port: address.port,
          path: '/orders',
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
        },
        (response: IncomingMessage) => {
          const chunks: Buffer[] = [];
          response.on('data', (chunk: Buffer) => chunks.push(chunk));
          response.on('end', () => resolve({
            statusCode: response.statusCode ?? 0,
            body: Buffer.concat(chunks).toString('utf8'),
          }));
          response.on('error', reject);
        },
      );
      request.write(JSON.stringify(body));
      request.end();
    });
  };

  beforeAll(async () => {
    createOrder = jest.fn();
    const module = await Test.createTestingModule({
      controllers: [OrdersController],
      providers: [
        { provide: PrismaOrderRepository, useValue: { findProductForOrder: jest.fn() } },
        { provide: CreateOrderUseCase, useValue: { execute: createOrder } },
        { provide: ConfirmDeliveryUseCase, useValue: {} },
        { provide: MarkAsShippedUseCase, useValue: {} },
        { provide: MarkAsDeliveredUseCase, useValue: {} },
        { provide: CancelOrderUseCase, useValue: {} },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    app = module.createNestApplication();
    app.useGlobalPipes(createValidationPipe());
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new TransformInterceptor(), new EitherInterceptor());
    await app.init();
    await app.listen(0);
  });

  afterAll(async () => app.close());

  it('returns the complete server-derived order in the success envelope', async () => {
    createOrder.mockResolvedValue(right({
      id: 'order-1',
      buyerId: 'buyer-1',
      sellerId: 'seller-1',
      productId: '550e8400-e29b-41d4-a716-446655440000',
      amount: 1055,
      platformFee: 106,
      sellerAmount: 949,
      status: 'PENDING',
      escrowStatus: 'HELD',
      createdAt: new Date('2026-09-12T00:00:00.000Z'),
    }));

    const response = await post({ productId: '550e8400-e29b-41d4-a716-446655440000' });

    expect(response.statusCode).toBe(201);
    expect(JSON.parse(response.body)).toEqual({
      success: true,
      data: expect.objectContaining({
        id: 'order-1',
        amount: 1055,
        platformFee: 106,
        sellerAmount: 949,
        status: 'PENDING',
        escrowStatus: 'HELD',
      }),
    });
  });

  it.each([
    ['invalid product input', {}, 'VALIDATION_ERROR'],
    ['unavailable product', { productId: '550e8400-e29b-41d4-a716-446655440000' }, 'BAD_REQUEST'],
    ['out-of-stock product', { productId: '550e8400-e29b-41d4-a716-446655440000' }, 'BAD_REQUEST'],
  ])('returns a structured error envelope for %s', async (_name, body, code) => {
    if (code === 'VALIDATION_ERROR') {
      createOrder.mockClear();
    } else {
      createOrder.mockResolvedValue(left(new BadRequestError(
        code === 'BAD_REQUEST' && _name === 'out-of-stock product'
          ? 'Produto sem estoque'
          : 'Produto não está mais disponível',
      )));
    }

    const response = await post(body);
    const parsed = JSON.parse(response.body) as { success: boolean; error: { code: string; message: string } };

    expect(response.statusCode).toBe(code === 'VALIDATION_ERROR' ? 400 : 400);
    expect(parsed.success).toBe(false);
    expect(parsed.error.code).toBe(code);
    expect(parsed.error.message).toEqual(expect.any(String));
  });
});
