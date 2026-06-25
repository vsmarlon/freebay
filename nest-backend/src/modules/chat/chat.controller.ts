import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { SendMessageUseCase } from './usecases/send-message.usecase';
import { GetConversationsUseCase } from './usecases/get-conversations.usecase';
import { GetMessagesUseCase } from './usecases/get-messages.usecase';
import { StartConversationUseCase } from './usecases/start-conversation.usecase';
import { AcceptConversationUseCase } from './usecases/accept-conversation.usecase';
import { GetUnifiedConversationsUseCase } from './usecases/get-unified-conversations.usecase';
import { ArchiveConversationUseCase } from './usecases/archive-conversation.usecase';
import { DeleteConversationUseCase } from './usecases/delete-conversation.usecase';
import { SetConversationThemeUseCase } from './usecases/set-conversation-theme.usecase';
import { SetConversationBackgroundUseCase } from './usecases/set-conversation-background.usecase';
import { StartConversationDTO, SendMessageDTO, ConversationResponse, UpdatePreferenceDTO } from './dtos/chat.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@ApiTags('Chat')
@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(
    private getConversationsUseCase: GetConversationsUseCase,
    private getMessagesUseCase: GetMessagesUseCase,
    private sendMessageUseCase: SendMessageUseCase,
    private startConversationUseCase: StartConversationUseCase,
    private acceptConversationUseCase: AcceptConversationUseCase,
    private getUnifiedConversationsUseCase: GetUnifiedConversationsUseCase,
    private archiveConversationUseCase: ArchiveConversationUseCase,
    private deleteConversationUseCase: DeleteConversationUseCase,
    private setConversationThemeUseCase: SetConversationThemeUseCase,
    private setConversationBackgroundUseCase: SetConversationBackgroundUseCase,
  ) {}

  @Get('conversations')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get all conversations (direct + order)', auth: true, responseType: ConversationResponse })
  async getConversations(@CurrentUser() user: AuthUser, @Query('q') query?: string) {
    const result = await this.getUnifiedConversationsUseCase.execute(user.userId, query);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return { conversations: result.value };
  }

  @Get('direct')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get only direct conversations (legacy)', auth: true })
  async getDirectConversations(@CurrentUser() user: AuthUser) {
    const result = await this.getConversationsUseCase.execute(user.userId);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return { conversations: result.value };
  }

  @Get('archived')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get archived conversations', auth: true })
  async getArchivedConversations(@CurrentUser() user: AuthUser) {
    const result = await this.getUnifiedConversationsUseCase.execute(user.userId, undefined, true);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return { conversations: result.value };
  }

  @Post('conversations')
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Start a conversation', auth: true, bodyType: StartConversationDTO, responseStatus: 201 })
  async startConversation(@CurrentUser() user: AuthUser, @Body() body: StartConversationDTO) {
    const result = await this.startConversationUseCase.execute(user.userId, body.targetUserId);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return result.value;
  }

  @Post('conversations/:id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Accept conversation', auth: true })
  async acceptConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.acceptConversationUseCase.execute(id, user.userId);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return result.value;
  }

  @Get('conversations/:id')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get conversation messages', auth: true })
  async getConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.getMessagesUseCase.execute(id, user.userId);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return { messages: result.value };
  }

  @Post('conversations/:id/messages')
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Send a message', auth: true, bodyType: SendMessageDTO, responseStatus: 201 })
  async sendMessage(@Param('id') id: string, @Body() body: SendMessageDTO, @CurrentUser() user: AuthUser) {
    const result = await this.sendMessageUseCase.execute({ senderId: user.userId, conversationId: id, content: body.content });
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return result.value;
  }

  @Patch('conversations/:id/archive')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Archive or unarchive a conversation', auth: true })
  async archiveConversation(@Param('id') id: string, @Body() body: { archived: boolean }, @CurrentUser() user: AuthUser) {
    const result = await this.archiveConversationUseCase.execute(user.userId, id, body.archived);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return { preference: result.value };
  }

  @Delete('conversations/:id')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Soft-delete a conversation', auth: true })
  async deleteConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.deleteConversationUseCase.execute(user.userId, id);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return { deleted: true };
  }

  @Patch('conversations/:id/theme')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Set conversation theme', auth: true })
  async setTheme(@Param('id') id: string, @Body() body: UpdatePreferenceDTO, @CurrentUser() user: AuthUser) {
    const result = await this.setConversationThemeUseCase.execute(user.userId, id, body.theme);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return { preference: result.value };
  }

  @Patch('conversations/:id/background')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Set conversation background', auth: true })
  async setBackground(@Param('id') id: string, @Body() body: { backgroundUrl: string }, @CurrentUser() user: AuthUser) {
    const result = await this.setConversationBackgroundUseCase.execute(user.userId, id, body.backgroundUrl);
    if (result.isLeft()) return left(new AppError(result.value.code, result.value.message));
    return { preference: result.value };
  }
}
