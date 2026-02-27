import { FastifyRequest, FastifyReply } from 'fastify';
import { randomUUID } from 'crypto';
import { LoginUseCase, RegisterUseCase, GuestUseCase } from '@/application/usecases/auth';
import { IUserRepository } from '@/domain/repositories';
import { isLeft } from '@/domain/either';
import { apiSuccess, apiError } from '@/presentation/response';
import { registerSchema, loginSchema } from '@/presentation/dtos';
import { env } from '@/env';

export class AuthController {
  private loginUseCase: LoginUseCase;
  private registerUseCase: RegisterUseCase;
  private guestUseCase: GuestUseCase;

  constructor(private userRepository: IUserRepository) {
    this.loginUseCase = new LoginUseCase(userRepository);
    this.registerUseCase = new RegisterUseCase(userRepository);
    this.guestUseCase = new GuestUseCase();
  }

  async guest(request: FastifyRequest, reply: FastifyReply) {
    const result = await this.guestUseCase.execute();

    const token = await reply.jwtSign(
      { isGuest: true, role: 'GUEST', jti: randomUUID() },
      { expiresIn: env.JWT_REFRESH_EXPIRES_IN },
    );

    return reply.code(200).send(
      apiSuccess({
        user: {
          id: result.userId,
          displayName: result.displayName,
          isGuest: true,
        },
        token,
      }),
    );
  }

  async register(request: FastifyRequest, reply: FastifyReply) {
    const parsed = registerSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.code(400).send(apiError('VALIDATION_ERROR', parsed.error.issues[0].message));
    }

    const result = await this.registerUseCase.execute(parsed.data);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    const token = await reply.jwtSign(
      { userId: result.value.user.id, role: 'USER', jti: randomUUID() },
      { expiresIn: env.JWT_EXPIRES_IN },
    );

    const refreshToken = await reply.jwtSign(
      { userId: result.value.user.id, role: 'USER', type: 'refresh', jti: randomUUID() },
      { expiresIn: env.JWT_REFRESH_EXPIRES_IN },
    );

    return reply.code(201).send(
      apiSuccess({
        user: result.value.user,
        token,
        refreshToken,
      }),
    );
  }

  async login(request: FastifyRequest, reply: FastifyReply) {
    const parsed = loginSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.code(400).send(apiError('VALIDATION_ERROR', parsed.error.issues[0].message));
    }

    const result = await this.loginUseCase.execute(parsed.data);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    const token = await reply.jwtSign(
      { userId: result.value.userId, role: 'USER', jti: randomUUID() },
      { expiresIn: env.JWT_EXPIRES_IN },
    );

    const refreshToken = await reply.jwtSign(
      { userId: result.value.userId, role: 'USER', type: 'refresh', jti: randomUUID() },
      { expiresIn: env.JWT_REFRESH_EXPIRES_IN },
    );

    return reply.code(200).send(
      apiSuccess({
        user: {
          id: result.value.userId,
          email: result.value.email,
          displayName: result.value.displayName,
        },
        token,
        refreshToken,
      }),
    );
  }
}
