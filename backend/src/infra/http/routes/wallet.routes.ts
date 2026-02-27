import { FastifyInstance } from 'fastify';
import { WalletController } from '@/presentation/controllers';
import { PrismaWalletRepository } from '@/infra/database/repositories';
import { authGuard } from '@/presentation/middlewares/auth-guard';

export async function walletRoutes(app: FastifyInstance) {
  const walletRepository = new PrismaWalletRepository();
  const controller = new WalletController(walletRepository);

  // All wallet routes require authentication
  app.addHook('preHandler', authGuard);

  app.get('/', (req, reply) => controller.getWallet(req, reply));
  app.post<{ Body: { amount: number } }>('/withdraw', (req, reply) =>
    controller.withdraw(req, reply),
  );

  // Transaction history
  app.get('/transactions', async (request, reply) => {
    // TODO: Implement with TransactionRepository
    return reply.send({ success: true, data: [] });
  });
}
