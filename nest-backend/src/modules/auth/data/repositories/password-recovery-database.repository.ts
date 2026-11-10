import { Injectable } from '@nestjs/common';
import { Prisma, PasswordRecoveryCode } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';

@Injectable()
export class PasswordRecoveryDatabaseRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly authSessionState: AuthSessionStateDatabaseRepository,
  ) {
  }

  async create(data: Prisma.PasswordRecoveryCodeCreateInput): RepositoryResponse<PasswordRecoveryCode> {
    return repositoryResponse(
      () => this.prisma.passwordRecoveryCode.create({ data }),
      'Erro ao criar código de recuperação',
    );
  }

  async findLatestActiveByEmail(email: string): RepositoryResponse<PasswordRecoveryCode | null> {
    return repositoryResponse(
      () =>
        this.prisma.passwordRecoveryCode.findFirst({
          where: { user: { email }, usedAt: null, expiresAt: { gt: new Date() } },
          orderBy: { requestedAt: 'desc' },
        }),
      'Erro ao buscar código de recuperação',
    );
  }

  async findLatestByEmail(email: string): RepositoryResponse<PasswordRecoveryCode | null> {
    return repositoryResponse(
      () =>
        this.prisma.passwordRecoveryCode.findFirst({
          where: { user: { email } },
          orderBy: { requestedAt: 'desc' },
        }),
      'Erro ao buscar código de recuperação',
    );
  }

  async reserveAttempt(id: string): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const recovery = await this.prisma.passwordRecoveryCode.findUnique({ where: { id }, select: { maxAttempts: true } });
      if (!recovery) return false;
      const result = await this.prisma.passwordRecoveryCode.updateMany({
        where: { id, usedAt: null, attempts: { lt: recovery.maxAttempts }, expiresAt: { gt: new Date() } },
        data: { attempts: { increment: 1 } },
      });
      return result.count === 1;
    }, 'Erro ao reservar tentativa de recuperação');
  }

  async markSent(id: string, resendMessageId?: string | null): RepositoryResponse<PasswordRecoveryCode> {
    return repositoryResponse(
      () =>
        this.prisma.passwordRecoveryCode.update({
          where: { id },
          data: { sentAt: new Date(), resendMessageId: resendMessageId ?? undefined },
        }),
      'Erro ao marcar código como enviado',
    );
  }

  async markUsed(id: string): RepositoryResponse<PasswordRecoveryCode> {
    return repositoryResponse(
      () =>
        this.prisma.passwordRecoveryCode.update({
          where: { id },
          data: { usedAt: new Date() },
        }),
      'Erro ao marcar código como usado',
    );
  }

  async findByCodeHash(codeHash: string): RepositoryResponse<PasswordRecoveryCode | null> {
    return repositoryResponse(
      () => this.prisma.passwordRecoveryCode.findFirst({ where: { codeHash }, orderBy: { requestedAt: 'desc' } }),
      'Erro ao buscar credencial de recuperação',
    );
  }

  async delete(id: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.passwordRecoveryCode.delete({ where: { id } });
    }, 'Erro ao invalidar código de recuperação');
  }

  async consumeAndUpdatePassword(id: string, userId: string, passwordHash: string): RepositoryResponse<boolean> {
    return repositoryResponse(async () => this.prisma.$transaction(async (tx) => {
      const cutoff = new Date();
      const claimed = await tx.passwordRecoveryCode.updateMany({
        where: { id, userId, usedAt: null, expiresAt: { gt: new Date() } },
        data: { usedAt: new Date() },
      });
      if (claimed.count !== 1) return false;
      await tx.user.update({ where: { id: userId }, data: { passwordHash } });
      await this.authSessionState.advanceInvalidBeforeInTransaction(tx, userId, cutoff);
      return true;
    }), 'Erro ao consumir código e atualizar senha');
  }

  async deleteManyForUser(userId: string): RepositoryResponse<void> {
    return repositoryResponse(
      async () => {
        await this.prisma.passwordRecoveryCode.deleteMany({ where: { userId } });
      },
      'Erro ao limpar códigos de recuperação',
    );
  }
}
