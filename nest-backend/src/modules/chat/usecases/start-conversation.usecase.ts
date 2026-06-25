import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { BlockRepository } from '@/modules/users/repositories/block.repository';
import { StartConversationOutput } from '../dtos/chat.dto';

@Injectable()
export class StartConversationUseCase {
  constructor(
    private prisma: PrismaService,
    private blockRepository: BlockRepository,
  ) {}

  async execute(initiatorId: string, targetUserId: string): Promise<Either<AppError, StartConversationOutput>> {
    if (initiatorId === targetUserId) {
      return left(new BadRequestError('Cannot start conversation with yourself'));
    }

    const targetUser = await this.prisma.user.findUnique({ where: { id: targetUserId } });
    if (!targetUser) {
      return left(new NotFoundError('User'));
    }

    const isBlocked = await this.blockRepository.isBlocked(initiatorId, targetUserId);
    if (isBlocked) {
      return left(new ForbiddenError('Você bloqueou este usuário'));
    }

    const isBlockedByOther = await this.blockRepository.isBlocked(targetUserId, initiatorId);
    if (isBlockedByOther) {
      return left(new ForbiddenError('Você foi bloqueado por este usuário'));
    }

    const existingConv = await this.prisma.directConversation.findFirst({
      where: {
        OR: [
          { user1Id: initiatorId, user2Id: targetUserId },
          { user1Id: targetUserId, user2Id: initiatorId },
        ],
      },
    });

    if (existingConv) {
      return right({ conversationId: existingConv.id, status: existingConv.status });
    }

    const isFollowing = await this.prisma.follow.findFirst({
      where: {
        followerId: initiatorId,
        followingId: targetUserId,
      },
    });

    const status = isFollowing ? 'ACTIVE' : 'PENDING';

    const newConv = await this.prisma.directConversation.create({
      data: {
        user1Id: initiatorId,
        user2Id: targetUserId,
        status,
      },
    });

    return right({ conversationId: newConv.id, status });
  }
}
