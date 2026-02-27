import { FastifyInstance } from 'fastify';
import { PrismaUserRepository } from '@/infra/database/repositories';
import { apiSuccess, apiError } from '@/presentation/response';
import { authGuard, requireNonGuest } from '@/presentation/middlewares/auth-guard';

export async function userRoutes(app: FastifyInstance) {
  const userRepository = new PrismaUserRepository();

  app.get('/me', { preHandler: [authGuard, requireNonGuest] }, async (request, reply) => {
    const userId = request.user.userId!;
    const user = await userRepository.findById(userId);
    if (!user) {
      return reply.code(404).send(apiError('NOT_FOUND', 'Usuário não encontrado'));
    }
    return reply.send(
      apiSuccess({
        id: user.id,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        city: user.city,
        state: user.state,
        isVerified: user.isVerified,
        reputationScore: user.reputationScore,
        totalReviews: user.totalReviews,
        createdAt: user.createdAt,
      }),
    );
  });

  // GET /users/:id — public profile
  app.get<{ Params: { id: string } }>('/:id', async (request, reply) => {
    const { id } = request.params;
    const user = await userRepository.findById(id);
    if (!user) {
      return reply.code(404).send(apiError('NOT_FOUND', 'Usuário não encontrado'));
    }
    return reply.send(
      apiSuccess({
        id: user.id,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        city: user.city,
        state: user.state,
        isVerified: user.isVerified,
        reputationScore: user.reputationScore,
        totalReviews: user.totalReviews,
        createdAt: user.createdAt,
      }),
    );
  });

  // PATCH /users/me — update own profile
  app.patch<{
    Body: Partial<{
      displayName: string;
      bio: string;
      city: string;
      state: string;
      avatarUrl: string;
    }>;
  }>('/me', { preHandler: [authGuard, requireNonGuest] }, async (request, reply) => {
    const userId = request.user.userId!;
    const updates = request.body;

    const updated = await userRepository.update(userId, updates);
    return reply.send(
      apiSuccess({
        id: updated.id,
        displayName: updated.displayName,
        avatarUrl: updated.avatarUrl,
        bio: updated.bio,
        city: updated.city,
        state: updated.state,
        isVerified: updated.isVerified,
        reputationScore: updated.reputationScore,
        totalReviews: updated.totalReviews,
        createdAt: updated.createdAt,
      }),
    );
  });
}
