import { Injectable } from '@nestjs/common';
import { Either, left, right, isLeft } from '@/shared/core/either';
import { AppError, ForbiddenError, NotFoundError } from '@/shared/core/errors';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';

@Injectable()
export class DeleteMessageUseCase {
  constructor(private readonly conversationRepository: ConversationDatabaseRepository) {}

  async execute(input: {
    messageId: string;
    userId: string;
    conversationId: string;
  }): Promise<Either<AppError, void>> {
    const msgResult = await this.conversationRepository.findDirectMessageById(input.messageId);
    if (isLeft(msgResult)) return left(msgResult.value);
    const msg = msgResult.value;
    if (!msg) return left(new NotFoundError('Message'));
    if (msg.senderId !== input.userId) return left(new ForbiddenError('Você só pode apagar suas próprias mensagens'));

    const deleteResult = await this.conversationRepository.softDeleteDirectMessage(input.messageId);
    if (isLeft(deleteResult)) return left(deleteResult.value);

    return right(undefined);
  }
}
