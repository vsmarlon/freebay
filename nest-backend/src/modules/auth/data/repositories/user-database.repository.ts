import { Injectable } from '@nestjs/common';
import { Prisma, User, PrismaClient } from '@prisma/client';
import { RepositoryResponse, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { UserRepository } from '../../domain/repositories/user.repository';
import { UserSearchResult, UserSuggestionResult } from '../../types/user-search.types';

@Injectable()
export class UserDatabaseRepository implements UserRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findById(id: string): RepositoryResponse<User | null> {
    try {
      return right(await this.prisma.user.findUnique({ where: { id } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar usuário'));
    }
  }

  async findByEmail(email: string): RepositoryResponse<User | null> {
    try {
      return right(await this.prisma.user.findUnique({ where: { email } }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar usuário'));
    }
  }

  async create(data: Prisma.UserCreateInput): RepositoryResponse<User> {
    try {
      return right(await this.prisma.user.create({ data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao criar usuário'));
    }
  }

  async update(id: string, data: Prisma.UserUpdateInput): RepositoryResponse<User> {
    try {
      return right(await this.prisma.user.update({ where: { id }, data }));
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao atualizar usuário'));
    }
  }

  async searchUsers(query: string, limit: number, cursor?: string): RepositoryResponse<UserSearchResult[]> {
    try {
      const users = await this.prisma.user.findMany({
        where: { displayName: { contains: query, mode: 'insensitive' } },
        take: limit,
        ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
        select: {
          id: true,
          displayName: true,
          avatarUrl: true,
          bio: true,
          isVerified: true,
          reputationScore: true,
          totalReviews: true,
          _count: { select: { followers: true, following: true } },
        },
      });
      return right(users as UserSearchResult[]);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao pesquisar usuários'));
    }
  }

  async getSuggestions(userId: string, limit: number): RepositoryResponse<UserSuggestionResult[]> {
    try {
      const following = await this.prisma.follow.findMany({
        where: { followerId: userId },
        select: { followingId: true },
      });
      const followingIds = following.map((f) => f.followingId);

      const suggestions = await this.prisma.user.findMany({
        where: {
          id: { not: userId },
          followers: { some: { followerId: { in: followingIds } } },
          NOT: { followers: { some: { followerId: userId } } },
        },
        take: limit,
        select: {
          id: true,
          displayName: true,
          avatarUrl: true,
          bio: true,
          isVerified: true,
          reputationScore: true,
          totalReviews: true,
          _count: { select: { followers: true, following: true } },
          followers: {
            where: { followerId: { in: followingIds } },
            select: { followerId: true },
          },
        },
      });

      return right(
        suggestions.map((u) => ({
          id: u.id,
          displayName: u.displayName,
          avatarUrl: u.avatarUrl,
          bio: u.bio,
          isVerified: u.isVerified,
          reputationScore: u.reputationScore,
          totalReviews: u.totalReviews,
          followersCount: u._count.followers,
          followingCount: u._count.following,
          mutualCount: u.followers.length,
        })),
      );
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar sugestões'));
    }
  }

  async findPaymentInfo(userId: string): RepositoryResponse<{ displayName: string; email: string; cpf: string | null } | null> {
    try {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: { displayName: true, email: true, cpf: true },
      });
      return right(user);
    } catch {
      return left(new AppError('DB_ERROR', 'Erro ao buscar informações de pagamento'));
    }
  }
}
