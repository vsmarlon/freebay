import { Injectable } from '@nestjs/common';
import { Prisma, PhoneVerificationCode, User } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';

class StalePhoneVerificationError extends Error {}

@Injectable()
export class PhoneVerificationDatabaseRepository {
  constructor(private readonly prisma: PrismaService) {
  }

  async create(data: Prisma.PhoneVerificationCodeCreateInput): RepositoryResponse<PhoneVerificationCode> {
    return repositoryResponse(() => this.prisma.phoneVerificationCode.create({ data }), 'Erro ao criar código de verificação');
  }

  async findLatestByUserId(userId: string): RepositoryResponse<PhoneVerificationCode | null> {
    return repositoryResponse(() => this.prisma.phoneVerificationCode.findFirst({
      where: { userId },
      orderBy: { requestedAt: 'desc' },
    }), 'Erro ao buscar código de verificação');
  }

  async reserveFailedAttempt(id: string): RepositoryResponse<boolean> {
    return repositoryResponse(async () => {
      const result = await this.prisma.phoneVerificationCode.updateMany({
        where: { id, usedAt: null, expiresAt: { gt: new Date() }, attempts: { lt: this.prisma.phoneVerificationCode.fields.maxAttempts } },
        data: { attempts: { increment: 1 } },
      });
      return result.count === 1;
    }, 'Erro ao registrar tentativa de verificação');
  }

  async consumeAndVerify(id: string, userId: string): RepositoryResponse<User | null> {
    return repositoryResponse(async () => {
      try {
        return await this.prisma.$transaction(async (tx) => {
          const verification = await tx.phoneVerificationCode.findUnique({
            where: { id },
            select: { phone: true },
          });
          if (!verification) return null;

          const consumed = await tx.phoneVerificationCode.updateMany({
            where: { id, userId, usedAt: null, expiresAt: { gt: new Date() }, attempts: { lt: tx.phoneVerificationCode.fields.maxAttempts } },
            data: { usedAt: new Date() },
          });
          if (consumed.count !== 1) return null;

          const updated = await tx.user.updateMany({
            where: { id: userId, phone: verification.phone },
            data: { phoneVerified: true, isVerified: true },
          });
          if (updated.count !== 1) throw new StalePhoneVerificationError();

          return tx.user.findUniqueOrThrow({ where: { id: userId } });
        });
      } catch (error: unknown) {
        if (error instanceof StalePhoneVerificationError) return null;
        throw error;
      }
    }, 'Erro ao concluir verificação do telefone');
  }

  async markSent(id: string, provider?: string | null, providerMessageId?: string | null): RepositoryResponse<PhoneVerificationCode> {
    return repositoryResponse(() => this.prisma.phoneVerificationCode.update({
      where: { id },
      data: {
        sentAt: new Date(),
        provider: provider ?? undefined,
        providerMessageId: providerMessageId ?? undefined,
      },
    }), 'Erro ao marcar código como enviado');
  }

  async deleteManyForUser(userId: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.phoneVerificationCode.deleteMany({ where: { userId } });
    }, 'Erro ao limpar códigos de verificação');
  }
}
