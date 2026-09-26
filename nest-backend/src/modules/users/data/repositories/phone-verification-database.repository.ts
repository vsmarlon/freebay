import { Injectable } from '@nestjs/common';
import { Prisma, PhoneVerificationCode } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';

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

  async incrementAttempts(id: string): RepositoryResponse<PhoneVerificationCode> {
    return repositoryResponse(() => this.prisma.phoneVerificationCode.update({
      where: { id },
      data: { attempts: { increment: 1 } },
    }), 'Erro ao incrementar tentativas');
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

  async markUsed(id: string): RepositoryResponse<PhoneVerificationCode> {
    return repositoryResponse(() => this.prisma.phoneVerificationCode.update({
      where: { id },
      data: { usedAt: new Date() },
    }), 'Erro ao marcar código como usado');
  }

  async deleteManyForUser(userId: string): RepositoryResponse<void> {
    return repositoryResponse(async () => {
      await this.prisma.phoneVerificationCode.deleteMany({ where: { userId } });
    }, 'Erro ao limpar códigos de verificação');
  }
}
