import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, BadRequestError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { BlockRepository } from '@/modules/users/repositories/block.repository';
import { SendMessageInput, SendMessageOutput } from '../dtos/chat.dto';

@Injectable()
export class SendMessageUseCase {
  constructor(
    private readonly conversationRepository: ConversationRepository,
    private readonly blockRepository: BlockRepository,
  ) {}

  async execute(input: SendMessageInput): Promise<Either<AppError, SendMessageOutput>> {
    const conversationResult = await this.conversationRepository.findDirectConversationById(input.conversationId);
    if (isLeft(conversationResult)) return left(conversationResult.value);
    const conversation = conversationResult.value;

    if (!conversation) return left(new NotFoundError('Conversation'));

    if (conversation.status === 'PENDING') {
      const isParticipant = conversation.user1Id === input.senderId || conversation.user2Id === input.senderId;
      if (!isParticipant) return left(new BadRequestError('Conversation is pending acceptance'));
    }

    const otherUserId = conversation.user1Id === input.senderId
      ? conversation.user2Id
      : conversation.user1Id;

    const [isBlocked, isBlockedByOther] = await Promise.all([
      this.blockRepository.isBlocked(input.senderId, otherUserId),
      this.blockRepository.isBlocked(otherUserId, input.senderId),
    ]);
    if (isBlocked) return left(new ForbiddenError('Você bloqueou este usuário'));
    if (isBlockedByOther) return left(new ForbiddenError('Você foi bloqueado por este usuário'));

    const messageResult = await this.conversationRepository.createDirectMessage({
      conversation: { connect: { id: input.conversationId } },
      sender: { connect: { id: input.senderId } },
      content: input.content,
      type: 'TEXT',
    }, true);
    if (isLeft(messageResult)) return left(messageResult.value);

    const updateResult = await this.conversationRepository.updateDirectConversation(input.conversationId, {
      lastMessageAt: new Date(),
    });
    if (isLeft(updateResult)) return left(updateResult.value);

    const msg = messageResult.value;
    return right({
      id: msg.id,
      conversationId: msg.conversationId,
      senderId: msg.senderId,
      content: msg.content ?? '',
      type: msg.type,
      createdAt: msg.createdAt,
    });
  }
}
