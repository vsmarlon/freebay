import { Injectable } from '@nestjs/common';
import { AppError, BadRequestError, NotFoundError } from '@/shared/core/errors';
import { Either, left, right } from '@/shared/core/either';
import { SafetyListRepository } from '../domain/repositories/safety-list.repository';
import { toUserBrief } from '../dtos/user-response.class';

@Injectable()
export class ManageSafetyListUseCase {
  constructor(private readonly lists: SafetyListRepository) {}

  async candidates(ownerId: string, search: string, selected: boolean, limit: number, offset: number) {
    const result = await this.lists.candidates(ownerId, search.trim(), selected, limit, offset);
    if (result.isLeft()) return left(result.value);
    return right({ users: result.value.map((user) => ({ ...toUserBrief(user), isCloseFriend: user.isCloseFriend })), limit, offset });
  }

  async list(ownerId: string, kind: 'closeFriends' | 'restricted', limit: number, offset: number) {
    const result = await this.lists.list(ownerId, kind, limit, offset);
    if (result.isLeft()) return left(result.value);
    return right({ users: result.value.map(toUserBrief), limit, offset });
  }

  async change(ownerId: string, memberId: string, kind: 'closeFriends' | 'restricted', add: boolean): Promise<Either<AppError, { active: boolean }>> {
    if (ownerId === memberId) return left(new BadRequestError('Não é possível adicionar a si mesmo'));
    const result = kind === 'closeFriends'
      ? add ? await this.lists.addCloseFriend(ownerId, memberId) : await this.lists.removeCloseFriend(ownerId, memberId)
      : add ? await this.lists.addRestriction(ownerId, memberId) : await this.lists.removeRestriction(ownerId, memberId);
    if (result.isLeft()) return left(result.value);
    if (add && !result.value) return left(kind === 'closeFriends'
      ? new BadRequestError('Somente seguidores não bloqueados podem ser amigos próximos')
      : new NotFoundError('Usuário'));
    return right({ active: add });
  }
}
