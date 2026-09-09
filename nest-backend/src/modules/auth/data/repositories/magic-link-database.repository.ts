import { Injectable } from '@nestjs/common';
import { Prisma, User, WebMagicLink } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { DatabaseError } from '@/shared/core/errors';
import { Either, left, right } from '@/shared/core/either';
import { MagicLinkRepository } from '../../domain/repositories/magic-link.repository';

@Injectable()
export class MagicLinkDatabaseRepository implements MagicLinkRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: Prisma.WebMagicLinkCreateInput): Promise<Either<DatabaseError, WebMagicLink>> {
    try {
      return right(await this.prisma.webMagicLink.create({ data }));
    } catch {
      return left(new DatabaseError('Erro ao criar link de acesso'));
    }
  }

  async recordSendAccepted(id: string, sendAcceptedAt: Date, resendMessageId: string): Promise<Either<DatabaseError, WebMagicLink>> {
    try {
      return right(await this.prisma.webMagicLink.update({ where: { id }, data: { sendAcceptedAt, resendMessageId } }));
    } catch {
      return left(new DatabaseError('Erro ao registrar envio do link'));
    }
  }

  async consume(tokenHash: string, now: Date): Promise<Either<DatabaseError, User | null>> {
    try {
      const user = await this.prisma.$transaction(async (tx: Prisma.TransactionClient) => {
          const link = await tx.webMagicLink.findFirst({ where: { tokenHash, consumedAt: null, activatedAt: { not: null }, expiresAt: { gt: now } } });
          if (!link) return null;
          const lockedUsers = await tx.$queryRaw<Array<{ id: string }>>(Prisma.sql`SELECT "id" FROM "User" WHERE lower("email") = lower(${link.email}) LIMIT 1 FOR UPDATE`);
          const existing = lockedUsers[0]
            ? await tx.user.findUnique({ where: { id: lockedUsers[0].id } })
            : null;
         if (existing?.suspendedAt) return null;
         const claimed = await tx.webMagicLink.updateMany({
           where: { tokenHash, consumedAt: null, activatedAt: { not: null }, expiresAt: { gt: now } },
          data: { consumedAt: now },
        });
        if (claimed.count !== 1) return null;

         if (existing) {
           await tx.wallet.upsert({ where: { userId: existing.id }, create: { userId: existing.id }, update: {} });
           return tx.user.update({ where: { id: existing.id }, data: { emailVerified: true, webConsentGrantedAt: link.consentAt, webConsentIp: link.requestedIp, webConsentUserAgent: link.userAgent } });
        }

        return tx.user.create({
          data: {
            email: link.email,
            displayName: 'FreeBay user',
            emailVerified: true,
            wallet: { create: {} },
            webConsentGrantedAt: link.consentAt,
            webConsentIp: link.requestedIp,
            webConsentUserAgent: link.userAgent,
          },
        });
      });
      return right(user);
    } catch {
      return left(new DatabaseError('Erro ao consumir link de acesso'));
    }
  }

  async deleteExpiredOrConsumed(before: Date, consumedBefore: Date): Promise<Either<DatabaseError, number>> {
    try {
      const result = await this.prisma.webMagicLink.deleteMany({ where: { OR: [
        { consumedAt: { not: null, lt: consumedBefore } }, { consumedAt: null, expiresAt: { lt: before } },
      ] } });
      return right(result.count);
    } catch { return left(new DatabaseError('Erro ao limpar links de acesso')); }
  }
}
