import { Injectable } from '@nestjs/common';
import { Prisma, PasswordRecoveryCode, PrismaClient } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PasswordRecoveryRepository } from '../../domain/repositories/password-recovery.repository';

@Injectable()
export class PasswordRecoveryDatabaseRepository implements PasswordRecoveryRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: Prisma.PasswordRecoveryCodeCreateInput): RepositoryResponse<PasswordRecoveryCode> {
    try {
      return right(await this.prisma.passwordRecoveryCode.create({ data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar código de recuperação'));
    }
  }

  async findLatestActiveByEmail(email: string): RepositoryResponse<PasswordRecoveryCode | null> {
    try {
      return right(
        await this.prisma.passwordRecoveryCode.findFirst({
          where: { user: { email }, usedAt: null, expiresAt: { gt: new Date() } },
          orderBy: { requestedAt: 'desc' },
        }),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar código de recuperação'));
    }
  }

  async findLatestByEmail(email: string): RepositoryResponse<PasswordRecoveryCode | null> {
    try {
      return right(
        await this.prisma.passwordRecoveryCode.findFirst({
          where: { user: { email } },
          orderBy: { requestedAt: 'desc' },
        }),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar código de recuperação'));
    }
  }

  async incrementAttempts(id: string): RepositoryResponse<PasswordRecoveryCode> {
    try {
      return right(
        await this.prisma.passwordRecoveryCode.update({
          where: { id },
          data: { attempts: { increment: 1 } },
        }),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao incrementar tentativas'));
    }
  }

  async markSent(id: string, resendMessageId?: string | null): RepositoryResponse<PasswordRecoveryCode> {
    try {
      return right(
        await this.prisma.passwordRecoveryCode.update({
          where: { id },
          data: { sentAt: new Date(), resendMessageId: resendMessageId ?? undefined },
        }),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao marcar código como enviado'));
    }
  }

  async markUsed(id: string): RepositoryResponse<PasswordRecoveryCode> {
    try {
      return right(
        await this.prisma.passwordRecoveryCode.update({
          where: { id },
          data: { usedAt: new Date() },
        }),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao marcar código como usado'));
    }
  }

  async deleteManyForUser(userId: string): RepositoryResponse<void> {
    try {
      await this.prisma.passwordRecoveryCode.deleteMany({ where: { userId } });
      return right(undefined);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao limpar códigos de recuperação'));
    }
  }
}
