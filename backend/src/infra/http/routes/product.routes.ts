import { FastifyInstance } from 'fastify';
import { ProductController } from '@/presentation/controllers';
import { PrismaProductRepository } from '@/infra/database/repositories';
import { authGuard } from '@/presentation/middlewares/auth-guard';

export async function productRoutes(app: FastifyInstance) {
  const productRepository = new PrismaProductRepository();
  const controller = new ProductController(productRepository);

  // Public
  app.get<{
    Querystring: {
      cursor?: string;
      limit?: string;
      search?: string;
      category?: string;
      minPrice?: string;
      maxPrice?: string;
    };
  }>('/', (req, reply) => controller.list(req, reply));
  app.get<{ Params: { id: string } }>('/:id', (req, reply) => controller.getById(req, reply));

  // Protected
  app.post('/', { preHandler: [authGuard] }, (req, reply) => controller.create(req, reply));
  app.delete<{ Params: { id: string } }>('/:id', { preHandler: [authGuard] }, (req, reply) =>
    controller.delete(req, reply),
  );
}
