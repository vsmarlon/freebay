import { Injectable } from '@nestjs/common';
import { Prisma, PhoneVerificationCode } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BasePrismaRepository } from '@/shared/infra/prisma/base-prisma.repository';
import { RepositoryResponse } from '@/shared/core/either';
import { PhoneVerificationRepository } from '../../domain/repositories/phone-verification.repository';

@Injectable()
export class PhoneVerificationDatabaseRepository extends BasePrismaRepository implements PhoneVerificationRepository {
  constructor(prisma: PrismaService) {
    super(prisma);
  }

  async create(data: Prisma.PhoneVerificationCodeCreateInput): RepositoryResponse<PhoneVerificationCode> {
    return this.safeRun(() => this.prisma.phoneVerificationCode.create({ data }), 'Erro ao criar código de verificação');
  }

  async findLatestByUserId(userId: string): RepositoryResponse<PhoneVerificationCode | null> {
    return this.safeRun(() => this.prisma.phoneVerificationCode.findFirst({
      where: { userId },
      orderBy: { requestedAt: 'desc' },
    }), 'Erro ao buscar código de verificação');
  }

  async incrementAttempts(id: string): RepositoryResponse<PhoneVerificationCode> {
    return this.safeRun(() => this.prisma.phoneVerificationCode.update({
      where: { id },
      data: { attempts: { increment: 1 } },
    }), 'Erro ao incrementar tentativas');
  }

  async markSent(id: string, provider?: string | null, providerMessageId?: string | null): RepositoryResponse<PhoneVerificationCode> {
    return this.safeRun(() => this.prisma.phoneVerificationCode.update({
      where: { id },
      data: {
        sentAt: new Date(),
        provider: provider ?? undefined,
        providerMessageId: providerMessageId ?? undefined,
      },
    }), 'Erro ao marcar código como enviado');
  }

  async markUsed(id: string): RepositoryResponse<PhoneVerificationCode> {
    return this.safeRun(() => this.prisma.phoneVerificationCode.update({
      where: { id },
      data: { usedAt: new Date() },
    }), 'Erro ao marcar código como usado');
  }

  async deleteManyForUser(userId: string): RepositoryResponse<void> {
    return this.safeRun(async () => {
      await this.prisma.phoneVerificationCode.deleteMany({ where: { userId } });
    }, 'Erro ao limpar códigos de verificação');
  }
}
