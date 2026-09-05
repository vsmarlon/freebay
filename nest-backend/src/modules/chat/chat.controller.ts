import { Controller, Body, Param, Query, HttpStatus, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { GetAuth, PostAuth, PatchAuth, CurrentUserId } from '@/shared/decorators';
import { StartConversationDTO, SendMessageDTO, UpdatePreferenceDTO, VerifyUrlDTO, ForwardMessagesDTO } from './dtos/chat.dto';
import { GetUnifiedConversationsUseCase } from './usecases/get-unified-conversations.usecase';
import { GetConversationsUseCase } from './usecases/get-conversations.usecase';
import { StartConversationUseCase } from './usecases/start-conversation.usecase';
import { AcceptConversationUseCase } from './usecases/accept-conversation.usecase';
import { GetMessagesUseCase } from './usecases/get-messages.usecase';
import { GetConversationMediaUseCase } from './usecases/get-conversation-media.usecase';
import { SendMessageUseCase } from './usecases/send-message.usecase';
import { ArchiveConversationUseCase } from './usecases/archive-conversation.usecase';
import { DeleteConversationUseCase } from './usecases/delete-conversation.usecase';
import { SetConversationThemeUseCase } from './usecases/set-conversation-theme.usecase';
import { SetConversationBackgroundUseCase } from './usecases/set-conversation-background.usecase';
import { DeleteMessageUseCase } from './usecases/delete-message.usecase';
import { ToggleReactionUseCase } from './usecases/toggle-reaction.usecase';
import { VerifyUrlSafetyUseCase } from './usecases/verify-url-safety.usecase';
import { ForwardMessagesUseCase } from './usecases/forward-messages.usecase';

@ApiTags('Chat')
@Controller('chat')
export class ChatController {
  constructor(
    private readonly getUnifiedConversations: GetUnifiedConversationsUseCase,
    private readonly getConversationsUseCase: GetConversationsUseCase,
    private readonly startConversationUseCase: StartConversationUseCase,
    private readonly acceptConversationUseCase: AcceptConversationUseCase,
    private readonly getMessagesUseCase: GetMessagesUseCase,
    private readonly getConversationMediaUseCase: GetConversationMediaUseCase,
    private readonly sendMessageUseCase: SendMessageUseCase,
    private readonly archiveConversationUseCase: ArchiveConversationUseCase,
    private readonly deleteConversationUseCase: DeleteConversationUseCase,
    private readonly setThemeUseCase: SetConversationThemeUseCase,
    private readonly setBackgroundUseCase: SetConversationBackgroundUseCase,
    private readonly deleteMessageUseCase: DeleteMessageUseCase,
    private readonly toggleReactionUseCase: ToggleReactionUseCase,
    private readonly verifyUrlSafetyUseCase: VerifyUrlSafetyUseCase,
    private readonly forwardMessagesUseCase: ForwardMessagesUseCase,
  ) {}

  @GetAuth('conversations', 'Get all conversations (direct + order)')
  async getConversations(@CurrentUserId() userId: string, @Query('q') query?: string) {
    return this.getUnifiedConversations.execute(userId, query);
  }

  @GetAuth('direct', 'Get only direct conversations')
  async getDirectConversations(@CurrentUserId() userId: string) {
    return this.getConversationsUseCase.execute(userId);
  }

  @GetAuth('archived', 'Get archived conversations')
  async getArchivedConversations(@CurrentUserId() userId: string) {
    return this.getUnifiedConversations.execute(userId, undefined, true);
  }

  @PostAuth('conversations', { summary: 'Start a conversation', bodyType: StartConversationDTO, responseStatus: 201, httpCode: HttpStatus.CREATED })
  async startConversation(@CurrentUserId() userId: string, @Body() body: StartConversationDTO) {
    return this.startConversationUseCase.execute(userId, body.targetUserId);
  }

  @PostAuth('conversations/:id/accept', { summary: 'Accept conversation', params: [{ name: 'id', description: 'Conversation UUID' }] })
  async acceptConversation(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.acceptConversationUseCase.execute(id, userId);
  }

  @GetAuth('conversations/:id', { summary: 'Get conversation messages', params: [{ name: 'id', description: 'Conversation UUID' }] })
  async getConversation(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.getMessagesUseCase.execute(id, userId);
  }

  @GetAuth('conversations/:id/messages', { summary: 'Get filtered messages by type (media)', params: [{ name: 'id', description: 'Conversation UUID' }] })
  async getFilteredMessages(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUserId() userId: string,
    @Query('type') type?: string,
    @Query('limit') limit?: string,
    @Query('cursor') cursor?: string,
  ) {
    return this.getConversationMediaUseCase.execute({
      userId,
      conversationId: id,
      type,
      limit: limit ? parseInt(limit, 10) : undefined,
      cursor,
    });
  }

  @PostAuth('conversations/:id/messages', { summary: 'Send a message', bodyType: SendMessageDTO, responseStatus: 201, httpCode: HttpStatus.CREATED, params: [{ name: 'id', description: 'Conversation UUID' }] })
  async sendMessage(@Param('id', ParseUUIDPipe) id: string, @Body() body: SendMessageDTO, @CurrentUserId() userId: string) {
    return this.sendMessageUseCase.execute({
      conversationId: id,
      senderId: userId,
      content: body.content,
      type: body.type,
      attachmentUrl: body.attachmentUrl,
      replyToId: body.replyToId,
      metadata: body.metadata,
      viewOnce: body.viewOnce,
    });
  }

  @PatchAuth('conversations/:id/archive', { summary: 'Archive or unarchive a conversation', params: [{ name: 'id', description: 'Conversation UUID' }] })
  async archiveConversation(@Param('id', ParseUUIDPipe) id: string, @Body() body: { archived: boolean }, @CurrentUserId() userId: string) {
    return this.archiveConversationUseCase.execute(userId, id, body.archived);
  }

  @PatchAuth('conversations/:id/delete', { summary: 'Soft-delete a conversation', params: [{ name: 'id', description: 'Conversation UUID' }] })
  async deleteConversation(@Param('id', ParseUUIDPipe) id: string, @CurrentUserId() userId: string) {
    return this.deleteConversationUseCase.execute(userId, id);
  }

  @PatchAuth('conversations/:id/theme', { summary: 'Set conversation theme', params: [{ name: 'id', description: 'Conversation UUID' }] })
  async setTheme(@Param('id', ParseUUIDPipe) id: string, @Body() body: UpdatePreferenceDTO, @CurrentUserId() userId: string) {
    return this.setThemeUseCase.execute(userId, id, body.theme);
  }

  @PatchAuth('conversations/:id/background', { summary: 'Set conversation background', params: [{ name: 'id', description: 'Conversation UUID' }] })
  async setBackground(@Param('id', ParseUUIDPipe) id: string, @Body() body: { backgroundUrl: string }, @CurrentUserId() userId: string) {
    return this.setBackgroundUseCase.execute(userId, id, body.backgroundUrl);
  }

  @PatchAuth('conversations/:convId/messages/:msgId/delete', {
    summary: 'Soft-delete a message (sender only)',
    params: [
      { name: 'convId', description: 'Conversation UUID' },
      { name: 'msgId', description: 'Message UUID' },
    ],
  })
  async deleteMessage(
    @Param('convId', ParseUUIDPipe) convId: string,
    @Param('msgId', ParseUUIDPipe) msgId: string,
    @CurrentUserId() userId: string,
  ) {
    return this.deleteMessageUseCase.execute({
      userId,
      messageId: msgId,
      conversationId: convId,
    });
  }

  @PostAuth('conversations/:convId/messages/:msgId/react', {
    summary: 'Toggle a reaction on a message',
    params: [
      { name: 'convId', description: 'Conversation UUID' },
      { name: 'msgId', description: 'Message UUID' },
    ],
  })
  async reactToMessage(
    @Param('convId', ParseUUIDPipe) convId: string,
    @Param('msgId', ParseUUIDPipe) msgId: string,
    @Body() body: { emoji: string },
    @CurrentUserId() userId: string,
  ) {
    return this.toggleReactionUseCase.execute({
      userId,
      messageId: msgId,
      emoji: body.emoji,
      conversationId: convId,
    });
  }

  @PostAuth('security/verify-url', { summary: 'Verify safety of external URL', bodyType: VerifyUrlDTO })
  async verifyUrl(@Body() body: VerifyUrlDTO) {
    return this.verifyUrlSafetyUseCase.execute(body.url);
  }

  @PostAuth('messages/forward', { summary: 'Forward messages to one or more conversations', bodyType: ForwardMessagesDTO, responseStatus: 201, httpCode: HttpStatus.CREATED })
  async forwardMessages(@CurrentUserId() userId: string, @Body() body: ForwardMessagesDTO) {
    return this.forwardMessagesUseCase.execute({
      userId,
      messageIds: body.messageIds,
      targetConversationIds: body.targetConversationIds,
      sourceConversationId: body.sourceConversationId,
    });
  }
}

