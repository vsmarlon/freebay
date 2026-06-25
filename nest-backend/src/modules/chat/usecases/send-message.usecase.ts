import { Injectable } from '@nestjs/common';
import { Either, left, right } from '@/shared/core/either';
import { AppError, NotFoundError, BadRequestError, ForbiddenError } from '@/shared/core/errors';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { USER_SELECT_MINIMAL } from '@/shared/utils/prisma-selects';
import { BlockRepository } from '@/modules/users/repositories/block.repository';
import { SendMessageInput, SendMessageOutput } from '../dtos/chat.dto';

@Injectable()
export class SendMessageUseCase {
  constructor(
    private prisma: PrismaService,
    private blockRepository: BlockRepository,
  ) {}

  async execute(input: SendMessageInput): Promise<Either<AppError, SendMessageOutput>> {
    const conversation = await this.prisma.directConversation.findUnique({
      where: { id: input.conversationId },
    });

    if (!conversation) {
      return left(new NotFoundError('Conversation'));
    }

    if (conversation.status === 'PENDING') {
      const isParticipant = conversation.user1Id === input.senderId || conversation.user2Id === input.senderId;
      if (!isParticipant) {
        return left(new BadRequestError('Conversation is pending acceptance'));
      }
    }

    const otherUserId = conversation.user1Id === input.senderId
      ? conversation.user2Id
      : conversation.user1Id;

    const isBlocked = await this.blockRepository.isBlocked(input.senderId, otherUserId);
    if (isBlocked) {
      return left(new ForbiddenError('Você bloqueou este usuário'));
    }

    const isBlockedByOther = await this.blockRepository.isBlocked(otherUserId, input.senderId);
    if (isBlockedByOther) {
      return left(new ForbiddenError('Você foi bloqueado por este usuário'));
    }

    const message = await this.prisma.directMessage.create({
      data: {
        conversation: { connect: { id: input.conversationId } },
        sender: { connect: { id: input.senderId } },
        content: input.content,
        type: 'TEXT',
      },
      include: {
        sender: { select: USER_SELECT_MINIMAL },
      },
    });

    await this.prisma.directConversation.update({
      where: { id: input.conversationId },
      data: { lastMessageAt: new Date() },
    });

    return right({
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      content: message.content ?? '',
      type: message.type,
      createdAt: message.createdAt,
    });
  }
}
