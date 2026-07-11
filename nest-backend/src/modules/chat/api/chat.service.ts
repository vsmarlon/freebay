import { Injectable } from '@nestjs/common';
import { isLeft } from '@/shared/core/either';
import { StartConversationUseCase } from '../usecases/start-conversation.usecase';
import { SendMessageUseCase } from '../usecases/send-message.usecase';
import { GetConversationsUseCase } from '../usecases/get-conversations.usecase';
import { GetMessagesUseCase } from '../usecases/get-messages.usecase';
import { AcceptConversationUseCase } from '../usecases/accept-conversation.usecase';
import { GetUnifiedConversationsUseCase } from '../usecases/get-unified-conversations.usecase';
import { ArchiveConversationUseCase } from '../usecases/archive-conversation.usecase';
import { DeleteConversationUseCase } from '../usecases/delete-conversation.usecase';
import { SetConversationThemeUseCase } from '../usecases/set-conversation-theme.usecase';
import { SetConversationBackgroundUseCase } from '../usecases/set-conversation-background.usecase';
import { DeleteMessageUseCase } from '../usecases/delete-message.usecase';
import { ToggleReactionUseCase } from '../usecases/toggle-reaction.usecase';
import { StartConversationDTO, SendMessageDTO } from '../dtos/chat.dto';

@Injectable()
export class ChatService {
  constructor(
    private readonly getConversationsUseCase: GetConversationsUseCase,
    private readonly getMessagesUseCase: GetMessagesUseCase,
    private readonly sendMessageUseCase: SendMessageUseCase,
    private readonly startConversationUseCase: StartConversationUseCase,
    private readonly acceptConversationUseCase: AcceptConversationUseCase,
    private readonly getUnifiedConversationsUseCase: GetUnifiedConversationsUseCase,
    private readonly archiveConversationUseCase: ArchiveConversationUseCase,
    private readonly deleteConversationUseCase: DeleteConversationUseCase,
    private readonly setConversationThemeUseCase: SetConversationThemeUseCase,
    private readonly setConversationBackgroundUseCase: SetConversationBackgroundUseCase,
    private readonly deleteMessageUseCase: DeleteMessageUseCase,
    private readonly toggleReactionUseCase: ToggleReactionUseCase,
  ) {}

  async getConversations(userId: string, query?: string, archived?: boolean) {
    const result = await this.getUnifiedConversationsUseCase.execute(userId, query, archived);
    if (isLeft(result)) throw result.value;
    return { conversations: result.value };
  }

  async getDirectConversations(userId: string) {
    const result = await this.getConversationsUseCase.execute(userId);
    if (isLeft(result)) throw result.value;
    return { conversations: result.value };
  }

  async startConversation(userId: string, body: StartConversationDTO) {
    const result = await this.startConversationUseCase.execute(userId, body.targetUserId);
    if (isLeft(result)) throw result.value;
    return result.value;
  }

  async acceptConversation(conversationId: string, userId: string) {
    const result = await this.acceptConversationUseCase.execute(conversationId, userId);
    if (isLeft(result)) throw result.value;
    return result.value;
  }

  async getMessages(conversationId: string, userId: string) {
    const result = await this.getMessagesUseCase.execute(conversationId, userId);
    if (isLeft(result)) throw result.value;
    return { messages: result.value };
  }

  async sendMessage(userId: string, conversationId: string, body: SendMessageDTO) {
    const result = await this.sendMessageUseCase.execute({
      senderId: userId,
      conversationId,
      content: body.content,
      type: body.type,
      attachmentUrl: body.attachmentUrl,
      replyToId: body.replyToId,
      metadata: body.metadata,
    });
    if (isLeft(result)) throw result.value;
    return result.value;
  }

  async archiveConversation(userId: string, conversationId: string, archived: boolean) {
    const result = await this.archiveConversationUseCase.execute(userId, conversationId, archived);
    if (isLeft(result)) throw result.value;
    return { preference: result.value };
  }

  async deleteConversation(userId: string, conversationId: string) {
    const result = await this.deleteConversationUseCase.execute(userId, conversationId);
    if (isLeft(result)) throw result.value;
    return { deleted: true };
  }

  async setTheme(userId: string, conversationId: string, theme: string) {
    const result = await this.setConversationThemeUseCase.execute(userId, conversationId, theme);
    if (isLeft(result)) throw result.value;
    return { preference: result.value };
  }

  async setBackground(userId: string, conversationId: string, backgroundUrl: string) {
    const result = await this.setConversationBackgroundUseCase.execute(userId, conversationId, backgroundUrl);
    if (isLeft(result)) throw result.value;
    return { preference: result.value };
  }

  async deleteMessage(userId: string, messageId: string, conversationId: string) {
    const result = await this.deleteMessageUseCase.execute({ messageId, userId, conversationId });
    if (isLeft(result)) throw result.value;
    return { deleted: true };
  }

  async toggleReaction(userId: string, messageId: string, emoji: string, messageModel: 'DIRECT' | 'ORDER') {
    const result = await this.toggleReactionUseCase.execute({ userId, messageId, emoji, messageModel });
    if (isLeft(result)) throw result.value;
    return result.value;
  }
}
