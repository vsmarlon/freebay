import { FastifyReply, FastifyRequest } from 'fastify';
import { tokenBlacklistService } from '@/infra/redis';

export async function authGuard(request: FastifyRequest, reply: FastifyReply) {
  try {
    await request.jwtVerify();

    if (request.user.jti) {
      const isBlacklisted = await tokenBlacklistService.isBlacklisted(request.user.jti);
      if (isBlacklisted) {
        return reply.code(401).send({
          success: false,
          error: { code: 'TOKEN_BLACKLISTED', message: 'Token revogado' },
        });
      }
    }
  } catch {
    return reply
      .code(401)
      .send({ success: false, error: { code: 'UNAUTHORIZED', message: 'Unauthorized' } });
  }
}

export async function authGuardOptional(request: FastifyRequest) {
  try {
    await request.jwtVerify();

    if (request.user.jti) {
      const isBlacklisted = await tokenBlacklistService.isBlacklisted(request.user.jti);
      if (isBlacklisted) {
        throw new Error('Token blacklisted');
      }
    }
  } catch {
    // Continue without auth - request.user will be undefined
  }
}

export async function requireNonGuest(request: FastifyRequest, reply: FastifyReply) {
  if (request.user?.isGuest) {
    return reply.code(403).send({
      success: false,
      error: { code: 'GUEST_FORBIDDEN', message: 'Guest users cannot perform this action' },
    });
  }
}
