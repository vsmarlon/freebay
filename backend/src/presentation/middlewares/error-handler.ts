import { FastifyError, FastifyReply, FastifyRequest } from 'fastify';

export function errorHandler(error: FastifyError, _request: FastifyRequest, reply: FastifyReply) {
  const statusCode = error.statusCode ?? 500;

  if (statusCode >= 500) {
    console.error('[ERROR]', error);
  }

  return reply.code(statusCode).send({
    error: error.name ?? 'InternalServerError',
    message: error.message ?? 'An unexpected error occurred',
    statusCode,
  });
}
