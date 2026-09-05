import { Injectable } from '@nestjs/common';
import { Prisma, PasswordRecoveryCode } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { PasswordRecoveryRepository } from '../../domain/repositories/password-recovery.repository';

@Injectable()
export class PasswordRecoveryDatabaseRepository extends BasePrismaRepository implements PasswordRecoveryRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.PasswordRecoveryCodeCreateInput): RepositoryResponse<PasswordRecoveryCode> {
    return this.safeRun(
      () => this.prisma.passwordRecoveryCode.create({ data }),
      'Erro ao criar código de recuperação',
    );
  }

  async findLatestActiveByEmail(email: string): RepositoryResponse<PasswordRecoveryCode | null> {
    return this.safeRun(
      () =>
        this.prisma.passwordRecoveryCode.findFirst({
          where: { user: { email }, usedAt: null, expiresAt: { gt: new Date() } },
          orderBy: { requestedAt: 'desc' },
        }),
      'Erro ao buscar código de recuperação',
    );
  }

  async findLatestByEmail(email: string): RepositoryResponse<PasswordRecoveryCode | null> {
    return this.safeRun(
      () =>
        this.prisma.passwordRecoveryCode.findFirst({
          where: { user: { email } },
          orderBy: { requestedAt: 'desc' },
        }),
      'Erro ao buscar código de recuperação',
    );
  }

  async incrementAttempts(id: string): RepositoryResponse<PasswordRecoveryCode> {
    return this.safeRun(
      () =>
        this.prisma.passwordRecoveryCode.update({
          where: { id },
          data: { attempts: { increment: 1 } },
        }),
      'Erro ao incrementar tentativas',
    );
  }

  async markSent(id: string, resendMessageId?: string | null): RepositoryResponse<PasswordRecoveryCode> {
    return this.safeRun(
      () =>
        this.prisma.passwordRecoveryCode.update({
          where: { id },
          data: { sentAt: new Date(), resendMessageId: resendMessageId ?? undefined },
        }),
      'Erro ao marcar código como enviado',
    );
  }

  async markUsed(id: string): RepositoryResponse<PasswordRecoveryCode> {
    return this.safeRun(
      () =>
        this.prisma.passwordRecoveryCode.update({
          where: { id },
          data: { usedAt: new Date() },
        }),
      'Erro ao marcar código como usado',
    );
  }

  async deleteManyForUser(userId: string): RepositoryResponse<void> {
    return this.safeRun(
      async () => {
        await this.prisma.passwordRecoveryCode.deleteMany({ where: { userId } });
      },
      'Erro ao limpar códigos de recuperação',
    );
  }
}
