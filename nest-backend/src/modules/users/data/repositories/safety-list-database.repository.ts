import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { repositoryResponse } from '@/shared/infra/prisma/repository-response';
import { SafetyListRepository } from '../../domain/repositories/safety-list.repository';

const userFields = { id: true, displayName: true, username: true, avatarUrl: true, avatarBlurHash: true, isVerified: true, reputationScore: true } as const;

@Injectable()
export class PrismaSafetyListRepository extends SafetyListRepository {
  constructor(private readonly prisma: PrismaService) { super(); }

  candidates(ownerId: string, search: string, selected: boolean, limit: number, offset: number) {
    return repositoryResponse(async () => {
      const users = await this.prisma.user.findMany({
        where: {
          id: { not: ownerId },
          OR: [
            { following: { some: { followingId: ownerId } } },
            { followers: { some: { followerId: ownerId } } },
          ],
          blocksGiven: { none: { blockedId: ownerId } },
          blocksReceived: { none: { blockerId: ownerId } },
          ...(selected ? { closeFriendsReceived: { some: { ownerId } } } : {}),
          ...(search ? { AND: [{ OR: [
            { displayName: { contains: search, mode: 'insensitive' } },
            { username: { contains: search, mode: 'insensitive' } },
          ] }] } : {}),
        },
        select: {
          ...userFields,
          closeFriendsReceived: { where: { ownerId }, select: { ownerId: true } },
        },
        orderBy: [{ displayName: 'asc' }, { id: 'asc' }],
        take: limit,
        skip: offset,
      });
      return users.map(({ closeFriendsReceived, ...user }) => ({
        ...user, isCloseFriend: closeFriendsReceived.length > 0,
      }));
    }, 'Erro ao buscar seguidores para amigos próximos');
  }

  list(ownerId: string, kind: 'closeFriends' | 'restricted', limit: number, offset: number) {
    return repositoryResponse(() => this.prisma.user.findMany({
      where: kind === 'closeFriends'
        ? { closeFriendsReceived: { some: { ownerId } } }
        : { restrictionsReceived: { some: { ownerId } } },
      select: userFields,
      orderBy: [{ displayName: 'asc' }, { id: 'asc' }],
      take: limit,
      skip: offset,
    }), 'Erro ao carregar lista de segurança');
  }

  addCloseFriend(ownerId: string, memberId: string) {
    return repositoryResponse(async () => this.prisma.$transaction(async (tx) => {
      const eligible = await tx.follow.findFirst({
        where: { OR: [
          { followerId: memberId, followingId: ownerId },
          { followerId: ownerId, followingId: memberId },
        ] }, select: { id: true },
      });
      const blocked = await tx.block.findFirst({
        where: { OR: [
          { blockerId: ownerId, blockedId: memberId },
          { blockerId: memberId, blockedId: ownerId },
        ] }, select: { id: true },
      });
      if (!eligible || blocked) return false;
      await tx.closeFriend.upsert({
        where: { ownerId_memberId: { ownerId, memberId } },
        create: { ownerId, memberId }, update: {},
      });
      return true;
    }), 'Erro ao adicionar amigo próximo');
  }

  removeCloseFriend(ownerId: string, memberId: string) {
    return repositoryResponse(async () => {
      await this.prisma.closeFriend.deleteMany({ where: { ownerId, memberId } });
    }, 'Erro ao remover amigo próximo');
  }

  addRestriction(ownerId: string, restrictedId: string) {
    return repositoryResponse(async () => this.prisma.$transaction(async (tx) => {
      const user = await tx.user.findUnique({ where: { id: restrictedId }, select: { id: true } });
      if (!user) return false;
      await tx.restriction.upsert({
        where: { ownerId_restrictedId: { ownerId, restrictedId } },
        create: { ownerId, restrictedId }, update: {},
      });
      return true;
    }), 'Erro ao restringir usuário');
  }

  removeRestriction(ownerId: string, restrictedId: string) {
    return repositoryResponse(async () => {
      await this.prisma.restriction.deleteMany({ where: { ownerId, restrictedId } });
    }, 'Erro ao remover restrição');
  }
}
