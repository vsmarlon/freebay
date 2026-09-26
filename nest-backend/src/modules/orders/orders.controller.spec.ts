import { Test, TestingModule } from '@nestjs/testing';
import { OrdersController } from './orders.controller';
import { PrismaOrderRepository } from './data/repositories/order-database.repository';
import { CreateOrderUseCase } from './usecases/create-order.usecase';
import { ConfirmDeliveryUseCase } from './usecases/confirm-delivery.usecase';
import { MarkAsShippedUseCase } from './usecases/mark-as-shipped.usecase';
import { MarkAsDeliveredUseCase } from './usecases/mark-as-delivered.usecase';
import { CancelOrderUseCase } from './usecases/cancel-order.usecase';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { right, left } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';
import { IncomingMessage, request as httpRequest } from 'http';
import { AllExceptionsFilter } from '@/shared/http/exception-filter';
import { EitherInterceptor } from '@/shared/http/response.interceptor';
import { TransformInterceptor } from '@/shared/http/transform.interceptor';
import { createValidationPipe } from '@/shared/http/validation-pipe.factory';
import { GetOrderUseCase } from './usecases/get-order.usecase';
import { ListSalesOrdersUseCase } from './usecases/list-sales-orders.usecase';

describe('OrdersController', () => {
  let controller: OrdersController;
  let getOrder: jest.Mock;
  let listSalesOrders: jest.Mock;

  beforeEach(async () => {
    getOrder = jest.fn();
    listSalesOrders = jest.fn();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [OrdersController],
      providers: [
        { provide: PrismaOrderRepository, useValue: {} },
        { provide: CreateOrderUseCase, useValue: {} },
        { provide: ConfirmDeliveryUseCase, useValue: {} },
        { provide: MarkAsShippedUseCase, useValue: {} },
        { provide: MarkAsDeliveredUseCase, useValue: {} },
        { provide: CancelOrderUseCase, useValue: {} },
        { provide: GetOrderUseCase, useValue: { execute: getOrder } },
        { provide: ListSalesOrdersUseCase, useValue: { execute: listSalesOrders } },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = module.get<OrdersController>(OrdersController);
  });

  it('keeps the findOne response contract', async () => {
    const response = { order: { id: 'order-1' } };
    getOrder.mockResolvedValue(right(response));

    await expect(controller.findOne('order-1', { userId: 'user-1', role: 'USER' }))
      .resolves.toEqual(right(response));
  });

  it('delegates sales policy and preserves its result', async () => {
    const response = { items: [], hasMore: false, nextCursor: null };
    listSalesOrders.mockResolvedValue(right(response));

    await expect(controller.getMySales('seller-1', { limit: 2 }))
      .resolves.toEqual(right(response));
    expect(listSalesOrders).toHaveBeenCalledWith('seller-1', { limit: 2 });
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
        { provide: GetOrderUseCase, useValue: { execute: jest.fn() } },
        { provide: ListSalesOrdersUseCase, useValue: { execute: jest.fn() } },
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
