import { Injectable } from '@nestjs/common';
import { ConnectAccount, Prisma } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import { ConnectAccountSnapshot } from '../../types/connect.types';

@Injectable()
export class ConnectAccountDatabaseRepository
 
{
  constructor(private readonly prisma: PrismaService) {
  }

  async findByUserId(userId: string): RepositoryResponse<ConnectAccount | null> {
    return repositoryResponse(
      () => this.prisma.connectAccount.findUnique({ where: { userId } }),
      'Erro ao buscar conta Connect',
    );
  }

  async findByStripeAccountId(
    stripeAccountId: string,
  ): RepositoryResponse<ConnectAccount | null> {
    return repositoryResponse(
      () => this.prisma.connectAccount.findUnique({ where: { stripeAccountId } }),
      'Erro ao buscar conta Connect',
    );
  }

  async findUserContact(
    userId: string,
  ): RepositoryResponse<{ email: string; displayName: string } | null> {
    return repositoryResponse(
      () =>
        this.prisma.user.findUnique({
          where: { id: userId },
          select: { email: true, displayName: true },
        }),
      'Erro ao buscar usuário',
    );
  }

  async upsertFromSnapshot(
    userId: string,
    snapshot: ConnectAccountSnapshot,
    tx?: Prisma.TransactionClient,
  ): RepositoryResponse<ConnectAccount> {
    const client = tx ?? this.prisma;
    const fields = {
      transfersEnabled: snapshot.transfersEnabled,
      payoutsEnabled: snapshot.payoutsEnabled,
      detailsSubmitted: snapshot.detailsSubmitted,
      requirementsDue: snapshot.requirementsDue,
      ...(snapshot.country ? { country: snapshot.country } : {}),
      ...(snapshot.defaultCurrency ? { defaultCurrency: snapshot.defaultCurrency } : {}),
    };

    return repositoryResponse(
      () =>
        client.connectAccount.upsert({
          where: { userId },
          create: {
            user: { connect: { id: userId } },
            stripeAccountId: snapshot.stripeAccountId,
            country: snapshot.country,
            defaultCurrency: snapshot.defaultCurrency,
            transfersEnabled: snapshot.transfersEnabled,
            payoutsEnabled: snapshot.payoutsEnabled,
            detailsSubmitted: snapshot.detailsSubmitted,
            requirementsDue: snapshot.requirementsDue,
          },
          update: fields,
        }),
      'Erro ao salvar conta Connect',
    );
  }
}
