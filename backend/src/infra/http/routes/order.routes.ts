import { FastifyInstance } from 'fastify';
import {
  PrismaOrderRepository,
  PrismaWalletRepository,
  PrismaProductRepository,
} from '@/infra/database/repositories';
import { CreateOrderUseCase, ConfirmDeliveryUseCase } from '@/application/usecases/orders';
import { isLeft } from '@/domain/either';
import { apiSuccess, apiError } from '@/presentation/response';
import { createOrderSchema } from '@/presentation/dtos';
import { authGuard } from '@/presentation/middlewares/auth-guard';

export async function orderRoutes(app: FastifyInstance) {
  const orderRepository = new PrismaOrderRepository();
  const walletRepository = new PrismaWalletRepository();
  const productRepository = new PrismaProductRepository();
  const createOrderUseCase = new CreateOrderUseCase(orderRepository, walletRepository);
  const confirmDeliveryUseCase = new ConfirmDeliveryUseCase(orderRepository, walletRepository);

  // All order routes require authentication
  app.addHook('preHandler', authGuard);

  // POST /orders — create order from product
  app.post('/', async (request, reply) => {
    const parsed = createOrderSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.code(400).send(apiError('VALIDATION_ERROR', parsed.error.issues[0].message));
    }

    const product = await productRepository.findById(parsed.data.productId);
    if (!product) {
      return reply.code(404).send(apiError('NOT_FOUND', 'Produto não encontrado'));
    }

    const result = await createOrderUseCase.execute({
      buyerId: request.user.userId!,
      sellerId: product.sellerId,
      productId: product.id,
      amount: product.price,
      platformFeePercent: 10, // 10% fee
    });

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.code(201).send(apiSuccess(result.value));
  });

  // GET /orders/:id
  app.get<{ Params: { id: string } }>('/:id', async (request, reply) => {
    const { id } = request.params;
    const order = await orderRepository.findById(id);
    if (!order) {
      return reply.code(404).send(apiError('NOT_FOUND', 'Pedido não encontrado'));
    }
    return reply.send(apiSuccess(order));
  });

  // POST /orders/:id/confirm — buyer confirms delivery
  app.post<{ Params: { id: string } }>('/:id/confirm', async (request, reply) => {
    const { id } = request.params;
    const buyerId = request.user.userId!;

    const result = await confirmDeliveryUseCase.execute(id, buyerId);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  });
}
