import { Injectable } from '@nestjs/common';
import { Prisma, User } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { RepositoryResponse } from '@/shared/core/either';
import {
  UserProfileCounts,
  UserSearchResult,
  UserSuggestionResult,
  toUserSearchResult,
  toUserSuggestionResult,
} from '@/modules/users/types/search.types';
import { normalizeEmail } from '@/shared/utils/normalize-email';
import { postVisibilityWhere } from '@/modules/social/data/repositories/post-query-helpers';
import { storyAudienceWhere } from '@/modules/stories/data/repositories/story-database.repository';
import { CpfProtectionService } from '@/shared/utils/cpf-protection.service';
import { ConflictError } from '@/shared/core/errors';

@Injectable()
export class UserDatabaseRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly cpfProtection: CpfProtectionService,
  ) {
  }

  private withPlainCpf(user: User): User;
  private withPlainCpf(user: null): null;
  private withPlainCpf(user: User | null): User | null;
  private withPlainCpf(user: User | null): User | null {
    if (!user) return null;
    try {
      return { ...user, cpf: this.cpfProtection.decrypt(user.cpf) };
    } catch {
      // ponytail: unreadable legacy CPF must not block authentication or non-CPF profile reads.
      return { ...user, cpf: null };
    }
  }

  async findById(id: string): RepositoryResponse<User | null> {
    return repositoryResponse(
      async () => this.withPlainCpf(await this.prisma.user.findUnique({ where: { id } })),
      'Erro ao buscar usuário por ID',
    );
  }

  async findByEmail(email: string): RepositoryResponse<User | null> {
    return repositoryResponse(
      async () => this.withPlainCpf(await this.prisma.user.findUnique({ where: { email: normalizeEmail(email) } })),
      'Erro ao buscar usuário por email',
    );
  }

  async findByGoogleId(googleId: string): RepositoryResponse<User | null> {
    return repositoryResponse(
      async () => this.withPlainCpf(await this.prisma.user.findUnique({ where: { googleId } })),
      'Erro ao buscar usuário por Google ID',
    );
  }

  async findByUsername(username: string): RepositoryResponse<User | null> {
    const normalized = username.toLowerCase().trim();
    return repositoryResponse(
      async () => this.withPlainCpf(await this.prisma.user.findUnique({ where: { username: normalized } })),
      'Erro ao buscar usuário por username',
    );
  }

  async findByAppleId(appleId: string): RepositoryResponse<User | null> {
    return repositoryResponse(
      async () => this.withPlainCpf(await this.prisma.user.findUnique({ where: { appleId } })),
      'Erro ao buscar usuário por Apple ID',
    );
  }

  async findTakenUsernames(candidates: string[]): RepositoryResponse<string[]> {
    return repositoryResponse(async () => {
      const users = await this.prisma.user.findMany({
        where: { username: { in: candidates } },
        select: { username: true },
      });
      return users.flatMap((user) => user.username ? [user.username] : []);
    }, 'Erro ao buscar nomes de usuário');
  }

  async create(data: Prisma.UserCreateInput): RepositoryResponse<User> {
    return repositoryResponse(async () => {
      const cpf = data.cpf;
      const protectedData = cpf ? this.cpfProtection.protect(cpf) : null;
      if (cpf) await this.rejectLegacyDuplicate(this.cpfProtection.normalize(cpf));
      try {
        const user = await this.prisma.user.create({
          data: protectedData ? { ...data, ...protectedData } : { ...data, cpfHash: null },
        });
        return this.withPlainCpf(user);
      } catch (error: unknown) {
        if (protectedData && this.isCpfHashConflict(error)) throw new ConflictError('CPF/CNPJ já cadastrado');
        throw error;
      }
    }, 'Erro ao criar usuário');
  }

  async update(id: string, data: Prisma.UserUpdateInput): RepositoryResponse<User> {
    return repositoryResponse(async () => {
      const cpf = this.updatedCpf(data.cpf);
      const protectedData = typeof cpf === 'string' ? this.cpfProtection.protect(cpf) : null;
      if (typeof cpf === 'string') await this.rejectLegacyDuplicate(this.cpfProtection.normalize(cpf), id);
      const updated: Prisma.UserUpdateInput = cpf === undefined
        ? data
        : cpf === null
          ? { ...data, cpf: null, cpfHash: null }
          : { ...data, ...protectedData };
      try {
        return this.withPlainCpf(await this.prisma.user.update({ where: { id }, data: updated }));
      } catch (error: unknown) {
        if (protectedData && this.isCpfHashConflict(error)) throw new ConflictError('CPF/CNPJ já cadastrado');
        throw error;
      }
    }, 'Erro ao atualizar usuário');
  }

  private updatedCpf(value: Prisma.UserUpdateInput['cpf']): string | null | undefined {
    if (value === undefined || value === null || typeof value === 'string') return value;
    return value.set;
  }

  private async rejectLegacyDuplicate(normalizedCpf: string, exceptId?: string): Promise<void> {
    const duplicate = await this.prisma.$queryRaw<Array<{ id: string }>>(Prisma.sql`
      SELECT id FROM "User"
      WHERE cpf IS NOT NULL AND cpf NOT LIKE 'v1:%'
        AND upper(regexp_replace(cpf, '[^A-Za-z0-9]', '', 'g')) = ${normalizedCpf}
        AND (${exceptId ?? null}::text IS NULL OR id <> ${exceptId ?? null})
      LIMIT 1
    `);
    if (duplicate.length) throw new ConflictError('CPF/CNPJ já cadastrado');
  }

  private isCpfHashConflict(error: unknown): boolean {
    if (!(error instanceof Prisma.PrismaClientKnownRequestError) || error.code !== 'P2002') return false;
    const target: unknown = error.meta?.target;
    return Array.isArray(target)
      ? target.includes('cpfHash')
      : typeof target === 'string' && target.includes('cpfHash');
  }

  async updateAppleCredential(id: string, token: string | null): RepositoryResponse<User | null> {
    return repositoryResponse(async () => {
      try {
        return this.withPlainCpf(await this.prisma.user.update({
          where: { id, deletedAt: null },
          data: { appleRefreshTokenEncrypted: token },
        }));
      } catch (error: unknown) {
        if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025') return null;
        throw error;
      }
    }, 'Erro ao atualizar credencial Apple');
  }

  async searchUsers(query: string, limit: number, offset: number, viewerId?: string): RepositoryResponse<UserSearchResult[]> {
    return repositoryResponse(async () => {
      const trimmedQuery = query.trim();
      const handleOnly = trimmedQuery.startsWith('@');
      const q = handleOnly ? trimmedQuery.slice(1) : trimmedQuery;
      if (handleOnly && !q) return [];
      const escapeLike = (value: string) => value.replace(/[\\%_]/g, '\\$&');
      const escapedQuery = escapeLike(q);
      const prefixLike = `${escapedQuery}%`;
      const displayNameTerms = q.split(/\s+/).filter(Boolean);
      const displayNameFilter = displayNameTerms.length
        ? Prisma.join(displayNameTerms.map((term) => Prisma.sql`EXISTS (
            SELECT 1 FROM regexp_split_to_table(u."displayName", '[[:space:]]+') AS name_word
            WHERE name_word ILIKE ${`${escapeLike(term)}%`} ESCAPE CHR(92)
          )`), ' AND ')
        : Prisma.sql`TRUE`;

      const blockFilter = viewerId
        ? Prisma.sql`
            AND NOT EXISTS (SELECT 1 FROM "Block" b WHERE b."blockerId" = u.id AND b."blockedId" = ${viewerId})
            AND NOT EXISTS (SELECT 1 FROM "Block" b WHERE b."blockerId" = ${viewerId} AND b."blockedId" = u.id)
          `
        : Prisma.empty;

      const rows = await this.prisma.$queryRaw<
        Array<{
          id: string;
          displayName: string;
          username: string | null;
          avatarUrl: string | null;
          avatarBlurHash: string | null;
          bio: string | null;
          isVerified: boolean;
          reputationScore: number;
          totalReviews: number;
          followersCount: bigint;
          followingCount: bigint;
        }>
      >(Prisma.sql`
        SELECT
          u.id, u."displayName", u.username, u."avatarUrl", u."avatarBlurHash", u.bio, u."isVerified",
          u."reputationScore", u."totalReviews",
          (SELECT COUNT(*) FROM "Follow" f WHERE f."followingId" = u.id) AS "followersCount",
          (SELECT COUNT(*) FROM "Follow" f WHERE f."followerId" = u.id) AS "followingCount"
        FROM "User" u
        WHERE (${handleOnly ? Prisma.sql`u.username ILIKE ${prefixLike} ESCAPE CHR(92)` : Prisma.sql`(u.username ILIKE ${prefixLike} ESCAPE CHR(92) OR ${displayNameFilter})`})
        ${blockFilter}
        ORDER BY
          CASE
            WHEN lower(u.username) = lower(${q}) THEN 0
            WHEN u.username ILIKE ${prefixLike} ESCAPE CHR(92) THEN 1
            ELSE 2
          END,
          "followersCount" DESC,
          u.id ASC
         LIMIT ${limit + 1} OFFSET ${offset}
      `);

      return rows.map((r) =>
        toUserSearchResult(r, Number(r.followersCount), Number(r.followingCount)),
      );
    }, 'Erro ao pesquisar usuários');
  }

  async getSuggestions(userId: string, limit: number, offset: number): RepositoryResponse<UserSuggestionResult[]> {
    return repositoryResponse(async () => {
      const following = await this.prisma.follow.findMany({
        where: { followerId: userId },
        select: { followingId: true },
      });
      const followingIds = following.map((f) => f.followingId);

      const notBlocked: Prisma.UserWhereInput = {
        blocksGiven: { none: { blockedId: userId } },
        blocksReceived: { none: { blockerId: userId } },
      };

      const baseSelect = {
        id: true,
        displayName: true,
        username: true,
        avatarUrl: true,
        avatarBlurHash: true,
        bio: true,
        isVerified: true,
        reputationScore: true,
        totalReviews: true,
        _count: { select: { followers: true, following: true } },
      } as const;

      const suggestions = followingIds.length
        ? await this.prisma.user.findMany({
            where: {
              id: { not: userId },
              followers: { some: { followerId: { in: followingIds } } },
              NOT: { followers: { some: { followerId: userId } } },
              ...notBlocked,
            },
            select: {
              ...baseSelect,
              followers: {
                where: { followerId: { in: followingIds } },
                select: { followerId: true },
              },
            },
          })
        : [];

      const ranked = suggestions
        .map((u) =>
          toUserSuggestionResult(
            u,
            u._count.followers,
            u._count.following,
            u.followers.length,
          ),
        )
        .sort((a, b) =>
          b.mutualCount !== a.mutualCount
            ? b.mutualCount - a.mutualCount
             : b.followersCount !== a.followersCount
               ? b.followersCount - a.followersCount
               : a.id.localeCompare(b.id),
        )
        .slice(offset, offset + limit + 1);

      return ranked;
    }, 'Erro ao buscar sugestões');
  }

  async getProfileCounts(userId: string, viewerId?: string): RepositoryResponse<UserProfileCounts> {
    return repositoryResponse(async () => {
      const [postsCount, productsCount, activeStory] = await Promise.all([
        this.prisma.post.count({ where: { userId, deletedAt: null, AND: [postVisibilityWhere(viewerId)] } }),
        this.prisma.product.count({ where: { sellerId: userId, status: { not: 'DELETED' } } }),
        this.prisma.story.findFirst({
          where: { userId, deletedAt: null, expiresAt: { gt: new Date() }, AND: [storyAudienceWhere(viewerId ?? '')] },
          select: { id: true },
        }),
      ]);

      return { postsCount, productsCount, hasActiveStory: activeStory !== null };
    }, 'Erro ao buscar dados do perfil');
  }

  async findPaymentInfo(userId: string): RepositoryResponse<{ displayName: string; email: string; cpf: string | null } | null> {
    return repositoryResponse(async () => {
      const user = await this.prisma.user.findUnique({
          where: { id: userId },
          select: { displayName: true, email: true, cpf: true },
        });
      return user ? { ...user, cpf: this.cpfProtection.decrypt(user.cpf) } : null;
    }, 'Erro ao buscar informações de pagamento');
  }
}
