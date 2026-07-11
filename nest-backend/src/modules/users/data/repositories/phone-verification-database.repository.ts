import { Injectable } from '@nestjs/common';
import { Prisma, PhoneVerificationCode } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { PhoneVerificationRepository } from '../../domain/repositories/phone-verification.repository';

@Injectable()
export class PhoneVerificationDatabaseRepository implements PhoneVerificationRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: Prisma.PhoneVerificationCodeCreateInput): RepositoryResponse<PhoneVerificationCode> {
    try {
      return right(await this.prisma.phoneVerificationCode.create({ data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar código de verificação'));
    }
  }

  async findLatestByUserId(userId: string): RepositoryResponse<PhoneVerificationCode | null> {
    try {
      return right(
        await this.prisma.phoneVerificationCode.findFirst({
          where: { userId },
          orderBy: { requestedAt: 'desc' },
        }),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar código de verificação'));
    }
  }

  async incrementAttempts(id: string): RepositoryResponse<PhoneVerificationCode> {
    try {
      return right(
        await this.prisma.phoneVerificationCode.update({
          where: { id },
          data: { attempts: { increment: 1 } },
        }),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao incrementar tentativas'));
    }
  }

  async markSent(
    id: string,
    provider?: string | null,
    providerMessageId?: string | null,
  ): RepositoryResponse<PhoneVerificationCode> {
    try {
      return right(
        await this.prisma.phoneVerificationCode.update({
          where: { id },
          data: {
            sentAt: new Date(),
            provider: provider ?? undefined,
            providerMessageId: providerMessageId ?? undefined,
          },
        }),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao marcar código como enviado'));
    }
  }

  async markUsed(id: string): RepositoryResponse<PhoneVerificationCode> {
    try {
      return right(
        await this.prisma.phoneVerificationCode.update({
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
      await this.prisma.phoneVerificationCode.deleteMany({ where: { userId } });
      return right(undefined);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao limpar códigos de verificação'));
    }
  }
}
