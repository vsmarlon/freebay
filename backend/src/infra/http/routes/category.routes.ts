import { FastifyInstance } from 'fastify';
import { CategoryController } from '@/presentation/controllers';
import { PrismaCategoryRepository } from '@/infra/database/repositories';
import { authGuard, requireNonGuest } from '@/presentation/middlewares/auth-guard';

export async function categoryRoutes(app: FastifyInstance) {
  const categoryRepository = new PrismaCategoryRepository();
  const controller = new CategoryController(categoryRepository);

  // Public - get categories tree
  app.get('/', (req, reply) => controller.getCategories(req, reply));

  // Protected - create category (admin only in future)
  app.post<{ Body: { name: string; slug: string; parentId?: string } }>(
    '/',
    { preHandler: [authGuard, requireNonGuest] },
    (req, reply) => controller.createCategory(req, reply),
  );
}
