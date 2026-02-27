import { FastifyRequest, FastifyReply } from 'fastify';
import { GetWalletUseCase, WithdrawUseCase } from '@/application/usecases/wallet';
import { IWalletRepository } from '@/domain/repositories';
import { isLeft } from '@/domain/either';
import { apiSuccess, apiError } from '@/presentation/response';
import { withdrawSchema } from '@/presentation/dtos';

export class WalletController {
  private getWalletUseCase: GetWalletUseCase;
  private withdrawUseCase: WithdrawUseCase;

  constructor(private walletRepository: IWalletRepository) {
    this.getWalletUseCase = new GetWalletUseCase(walletRepository);
    this.withdrawUseCase = new WithdrawUseCase(walletRepository);
  }

  async getWallet(request: FastifyRequest, reply: FastifyReply) {
    const userId = request.user.userId!;
    const result = await this.getWalletUseCase.execute(userId);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(apiSuccess(result.value));
  }

  async withdraw(request: FastifyRequest, reply: FastifyReply) {
    const parsed = withdrawSchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.code(400).send(apiError('VALIDATION_ERROR', parsed.error.issues[0].message));
    }

    const userId = request.user.userId!;
    const { amount } = parsed.data;

    const result = await this.withdrawUseCase.execute(userId, amount);

    if (isLeft(result)) {
      return reply
        .code(result.value.statusCode)
        .send(apiError(result.value.code, result.value.message));
    }

    return reply.send(
      apiSuccess({
        message: 'Saque solicitado com sucesso',
        wallet: result.value,
      }),
    );
  }
}
