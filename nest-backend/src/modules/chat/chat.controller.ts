import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { StartConversationDTO, SendMessageDTO, UpdatePreferenceDTO } from './dtos/chat.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
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

@ApiTags('Chat')
@Controller('chat')
@UseGuards(JwtAuthGuard, NonGuestGuard)
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
  ) {}

  @Get('conversations')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get all conversations (direct + order)', auth: true })
  async getConversations(@CurrentUser() user: AuthUser, @Query('q') query?: string) {
    return this.getUnifiedConversations.execute(user.userId, query);
  }

  @Get('direct')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get only direct conversations', auth: true })
  async getDirectConversations(@CurrentUser() user: AuthUser) {
    return this.getConversationsUseCase.execute(user.userId);
  }

  @Get('archived')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get archived conversations', auth: true })
  async getArchivedConversations(@CurrentUser() user: AuthUser) {
    return this.getUnifiedConversations.execute(user.userId, undefined, true);
  }

  @Post('conversations')
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Start a conversation', auth: true, bodyType: StartConversationDTO, responseStatus: 201 })
  async startConversation(@CurrentUser() user: AuthUser, @Body() body: StartConversationDTO) {
    return this.startConversationUseCase.execute(user.userId, body.targetUserId);
  }

  @Post('conversations/:id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Accept conversation', auth: true })
  async acceptConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.acceptConversationUseCase.execute(id, user.userId);
  }

  @Get('conversations/:id')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get conversation messages', auth: true })
  async getConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.getMessagesUseCase.execute(id, user.userId);
  }

  @Get('conversations/:id/messages')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get filtered messages by type (media)', auth: true })
  async getFilteredMessages(
    @Param('id') id: string,
    @CurrentUser() user: AuthUser,
    @Query('type') type?: string,
    @Query('limit') limit?: string,
    @Query('cursor') cursor?: string,
  ) {
    return this.getConversationMediaUseCase.execute({
      userId: user.userId,
      conversationId: id,
      type,
      limit: limit ? parseInt(limit, 10) : undefined,
      cursor,
    });
  }

  @Post('conversations/:id/messages')
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Send a message', auth: true, bodyType: SendMessageDTO, responseStatus: 201 })
  async sendMessage(@Param('id') id: string, @Body() body: SendMessageDTO, @CurrentUser() user: AuthUser) {
    return this.sendMessageUseCase.execute({
      conversationId: id,
      senderId: user.userId,
      content: body.content,
      type: body.type,
      attachmentUrl: body.attachmentUrl,
      replyToId: body.replyToId,
      metadata: body.metadata,
      viewOnce: body.viewOnce,
    });
  }

  @Patch('conversations/:id/archive')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Archive or unarchive a conversation', auth: true })
  async archiveConversation(@Param('id') id: string, @Body() body: { archived: boolean }, @CurrentUser() user: AuthUser) {
    return this.archiveConversationUseCase.execute(user.userId, id, body.archived);
  }

  @Delete('conversations/:id')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Soft-delete a conversation', auth: true })
  async deleteConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.deleteConversationUseCase.execute(user.userId, id);
  }

  @Patch('conversations/:id/theme')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Set conversation theme', auth: true })
  async setTheme(@Param('id') id: string, @Body() body: UpdatePreferenceDTO, @CurrentUser() user: AuthUser) {
    return this.setThemeUseCase.execute(user.userId, id, body.theme);
  }

  @Patch('conversations/:id/background')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Set conversation background', auth: true })
  async setBackground(@Param('id') id: string, @Body() body: { backgroundUrl: string }, @CurrentUser() user: AuthUser) {
    return this.setBackgroundUseCase.execute(user.userId, id, body.backgroundUrl);
  }

  @Delete('conversations/:convId/messages/:msgId')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Soft-delete a message (sender only)', auth: true })
  async deleteMessage(
    @Param('convId') convId: string,
    @Param('msgId') msgId: string,
    @CurrentUser() user: AuthUser,
  ) {
    return this.deleteMessageUseCase.execute({
      userId: user.userId,
      messageId: msgId,
      conversationId: convId,
    });
  }

  @Post('conversations/:convId/messages/:msgId/react')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Toggle a reaction on a message', auth: true })
  async reactToMessage(
    @Param('convId') convId: string,
    @Param('msgId') msgId: string,
    @Body() body: { emoji: string },
    @CurrentUser() user: AuthUser,
  ) {
    return this.toggleReactionUseCase.execute({
      userId: user.userId,
      messageId: msgId,
      emoji: body.emoji,
      conversationId: convId,
    });
  }
}
