import { Controller, Get, Post, Body, Param, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { SendMessageUseCase, GetConversationsUseCase, GetMessagesUseCase, StartConversationUseCase, AcceptConversationUseCase } from './usecases/chat.usecase';
import { StartConversationDTO, SendMessageDTO, ConversationResponse, MessageResponse } from './dtos/chat.dto';
import { ApiDoc } from '@/shared/swagger/api-doc.decorator';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@ApiTags('Chat')
@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(
    private prisma: PrismaService,
    private getConversationsUseCase: GetConversationsUseCase,
    private getMessagesUseCase: GetMessagesUseCase,
    private sendMessageUseCase: SendMessageUseCase,
    private startConversationUseCase: StartConversationUseCase,
    private acceptConversationUseCase: AcceptConversationUseCase,
  ) {}

  @Get('conversations')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get conversations',
    auth: true,
    responseType: ConversationResponse,
  })
  async getConversations(@CurrentUser() user: AuthUser) {
    const userId = user.userId;
    const result = await this.getConversationsUseCase.execute(userId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { conversations: result.value };
  }

  @Post('conversations')
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Start a conversation',
    description: 'Start a new conversation with another user',
    auth: true,
    bodyType: StartConversationDTO,
    responseStatus: 201,
    errors: [{ status: 404, description: 'Target user not found' }],
  })
  async startConversation(@CurrentUser() user: AuthUser, @Body() body: StartConversationDTO) {
    const initiatorId = user.userId;
    const result = await this.startConversationUseCase.execute(initiatorId, body.targetUserId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('conversations/:id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Accept conversation',
    auth: true,
    params: [{ name: 'id', description: 'Conversation UUID' }],
    errors: [{ status: 404, description: 'Conversation not found' }],
  })
  async acceptConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.acceptConversationUseCase.execute(id, user.userId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get('conversations/:id')
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Get conversation messages',
    auth: true,
    params: [{ name: 'id', description: 'Conversation UUID' }],
    responseType: MessageResponse,
    errors: [{ status: 404, description: 'Conversation not found' }],
  })
  async getConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.getMessagesUseCase.execute(id, user.userId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { messages: result.value };
  }

  @Post('conversations/:id/messages')
  @HttpCode(HttpStatus.CREATED)
  @ApiBearerAuth()
  @ApiDoc({
    summary: 'Send a message',
    auth: true,
    bodyType: SendMessageDTO,
    responseStatus: 201,
    params: [{ name: 'id', description: 'Conversation UUID' }],
    errors: [{ status: 404, description: 'Conversation not found' }],
  })
  async sendMessage(
    @Param('id') id: string,
    @Body() body: SendMessageDTO,
    @CurrentUser() user: AuthUser,
  ) {
    const result = await this.sendMessageUseCase.execute({
      senderId: user.userId,
      conversationId: id,
      content: body.content,
    });
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }
}
