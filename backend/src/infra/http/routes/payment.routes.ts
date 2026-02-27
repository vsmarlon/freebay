import { FastifyInstance } from 'fastify';
import { apiSuccess } from '@/presentation/response';
import { authGuard } from '@/presentation/middlewares/auth-guard';

export async function paymentRoutes(app: FastifyInstance) {
  // POST /payments/pix — initiate Pix payment
  app.post<{ Body: { orderId: string } }>(
    '/pix',
    { preHandler: [authGuard] },
    async (request, reply) => {
      const { orderId } = request.body;
      // TODO: Call PagarmeClient or WooviClient to generate Pix charge
      return reply.send(
        apiSuccess({
          orderId,
          pixQrCode: 'TODO_GENERATE_QR',
          expiresAt: new Date(Date.now() + 30 * 60 * 1000).toISOString(),
        }),
      );
    },
  );

  // POST /payments/card — initiate credit card payment
  app.post<{ Body: { orderId: string } }>(
    '/card',
    { preHandler: [authGuard] },
    async (request, reply) => {
      const { orderId } = request.body;
      // TODO: Call PagarmeClient to process card payment
      return reply.send(
        apiSuccess({
          orderId,
          status: 'PROCESSING',
        }),
      );
    },
  );

  // POST /payments/webhook — payment provider webhook
  app.post('/webhook', async (request, reply) => {
    // TODO: Validate signature, update transaction status, release escrow if paid
    const body = request.body as Record<string, unknown>;
    console.log('[Webhook received]', JSON.stringify(body).slice(0, 200));
    return reply.send(apiSuccess({ received: true }));
  });

  // GET /payments/:orderId — payment status
  app.get<{ Params: { orderId: string } }>(
    '/:orderId',
    { preHandler: [authGuard] },
    async (request, reply) => {
      const { orderId } = request.params;
      // TODO: Query Transaction table by orderId
      return reply.send(
        apiSuccess({
          orderId,
          status: 'PENDING',
          message: 'Implementação pendente — conectar com Transaction repository',
        }),
      );
    },
  );
}
