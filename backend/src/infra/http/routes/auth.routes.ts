import { FastifyInstance } from 'fastify';
import { randomUUID } from 'crypto';
import { AuthController } from '@/presentation/controllers';
import { PrismaUserRepository } from '@/infra/database/repositories';
import { env } from '@/env';
import { tokenBlacklistService } from '@/infra/redis';

export async function authRoutes(app: FastifyInstance) {
  const userRepository = new PrismaUserRepository();
  const controller = new AuthController(userRepository);

  app.post('/register', (req, reply) => controller.register(req, reply));
  app.post('/login', (req, reply) => controller.login(req, reply));
  app.post('/guest', (req, reply) => controller.guest(req, reply));

  app.post('/refresh', async (request, reply) => {
    try {
      await request.jwtVerify();
      const payload = request.user;

      if (payload.type !== 'refresh') {
        return reply.code(401).send({
          success: false,
          error: { code: 'INVALID_TOKEN', message: 'Token inválido: esperado token de refresh' },
        });
      }

      const token = await reply.jwtSign(
        { userId: payload.userId, role: payload.role, jti: randomUUID() },
        { expiresIn: env.JWT_EXPIRES_IN },
      );
      const refreshToken = await reply.jwtSign(
        { userId: payload.userId, role: payload.role, type: 'refresh', jti: randomUUID() },
        { expiresIn: env.JWT_REFRESH_EXPIRES_IN },
      );
      return reply.send({ success: true, data: { token, refreshToken } });
    } catch {
      return reply
        .code(401)
        .send({ success: false, error: { code: 'INVALID_TOKEN', message: 'Token inválido' } });
    }
  });

  app.post('/logout', async (request, reply) => {
    try {
      await request.jwtVerify();
      const payload = request.user;

      const ttl = payload.exp - Math.floor(Date.now() / 1000);
      if (ttl > 0) {
        await tokenBlacklistService.add(payload.jti, ttl);
      }

      return reply.send({ success: true, data: { message: 'Logout realizado' } });
    } catch {
      return reply
        .code(401)
        .send({ success: false, error: { code: 'INVALID_TOKEN', message: 'Token inválido' } });
    }
  });
}
