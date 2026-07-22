import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { ChatService } from './api/chat.service';
import { StartConversationDTO, SendMessageDTO, UpdatePreferenceDTO } from './dtos/chat.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';

@ApiTags('Chat')
@Controller('chat')
@UseGuards(JwtAuthGuard, NonGuestGuard)
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('conversations')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get all conversations (direct + order)', auth: true })
  async getConversations(@CurrentUser() user: AuthUser, @Query('q') query?: string) {
    return this.chatService.getConversations(user.userId, query);
  }

  @Get('direct')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get only direct conversations (legacy)', auth: true })
  async getDirectConversations(@CurrentUser() user: AuthUser) {
    return this.chatService.getDirectConversations(user.userId);
  }

  @Get('archived')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get archived conversations', auth: true })
  async getArchivedConversations(@CurrentUser() user: AuthUser) {
    return this.chatService.getConversations(user.userId, undefined, true);
  }

  @Post('conversations')
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Start a conversation', auth: true, bodyType: StartConversationDTO, responseStatus: 201 })
  async startConversation(@CurrentUser() user: AuthUser, @Body() body: StartConversationDTO) {
    return this.chatService.startConversation(user.userId, body);
  }

  @Post('conversations/:id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Accept conversation', auth: true })
  async acceptConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.chatService.acceptConversation(id, user.userId);
  }

  @Get('conversations/:id')
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Get conversation messages', auth: true })
  async getConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.chatService.getMessages(id, user.userId);
  }

  @Post('conversations/:id/messages')
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Send a message', auth: true, bodyType: SendMessageDTO, responseStatus: 201 })
  async sendMessage(@Param('id') id: string, @Body() body: SendMessageDTO, @CurrentUser() user: AuthUser) {
    return this.chatService.sendMessage(user.userId, id, body);
  }

  @Patch('conversations/:id/archive')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Archive or unarchive a conversation', auth: true })
  async archiveConversation(@Param('id') id: string, @Body() body: { archived: boolean }, @CurrentUser() user: AuthUser) {
    return this.chatService.archiveConversation(user.userId, id, body.archived);
  }

  @Delete('conversations/:id')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Soft-delete a conversation', auth: true })
  async deleteConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.chatService.deleteConversation(user.userId, id);
  }

  @Patch('conversations/:id/theme')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Set conversation theme', auth: true })
  async setTheme(@Param('id') id: string, @Body() body: UpdatePreferenceDTO, @CurrentUser() user: AuthUser) {
    return this.chatService.setTheme(user.userId, id, body.theme);
  }

  @Patch('conversations/:id/background')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({ summary: 'Set conversation background', auth: true })
  async setBackground(@Param('id') id: string, @Body() body: { backgroundUrl: string }, @CurrentUser() user: AuthUser) {
    return this.chatService.setBackground(user.userId, id, body.backgroundUrl);
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
    return this.chatService.deleteMessage(user.userId, msgId, convId);
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
    return this.chatService.toggleReaction(user.userId, msgId, body.emoji, convId);
  }
}
