import { FastifyInstance } from 'fastify';
import { apiSuccess, apiError } from '@/presentation/response';
import { authGuard } from '@/presentation/middlewares/auth-guard';

export async function disputeRoutes(app: FastifyInstance) {
  // All dispute routes require authentication
  app.addHook('preHandler', authGuard);

  // POST /disputes — open dispute for an order
  app.post<{ Body: { orderId: string; reason: string } }>('/', async (request, reply) => {
    const userId = request.user.userId;
    const { orderId, reason } = request.body;

    if (!orderId || !reason) {
      return reply
        .code(400)
        .send(apiError('VALIDATION_ERROR', 'orderId e reason são obrigatórios'));
    }

    // TODO: Create dispute via DisputeUseCase
    return reply.code(201).send(
      apiSuccess({
        orderId,
        openedById: userId,
        reason,
        status: 'OPEN',
        message: 'Disputa aberta — aguardando resposta do vendedor',
      }),
    );
  });

  // POST /disputes/:id/evidence — submit evidence
  app.post<{ Params: { id: string } }>('/:id/evidence', async (request, reply) => {
    const { id } = request.params;
    // TODO: Save evidence to Dispute record
    return reply.send(
      apiSuccess({
        disputeId: id,
        evidenceReceived: true,
      }),
    );
  });

  // POST /disputes/:id/resolve — admin resolves dispute
  app.post<{ Params: { id: string }; Body: { resolution: string } }>(
    '/:id/resolve',
    async (request, reply) => {
      const { id } = request.params;
      const { resolution } = request.body;

      // TODO: Only admins can resolve — check role
      return reply.send(
        apiSuccess({
          disputeId: id,
          resolution,
          status: 'RESOLVED',
        }),
      );
    },
  );
}
