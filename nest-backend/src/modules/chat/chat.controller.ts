import { Controller, Get, Post, Body, Param, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { CurrentUser } from '@/shared/decorators/current-user.decorator';
import { AuthUser } from '@/shared/core/types';
import { SendMessageUseCase, GetConversationsUseCase, GetMessagesUseCase, StartConversationUseCase, AcceptConversationUseCase } from './usecases/chat.usecase';
import { StartConversationInput } from './dtos/chat.dto';
import { left } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

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
  async startConversation(@CurrentUser() user: AuthUser, @Body() body: StartConversationInput) {
    const initiatorId = user.userId;
    const result = await this.startConversationUseCase.execute(initiatorId, body.targetUserId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Post('conversations/:id/accept')
  @HttpCode(HttpStatus.OK)
  async acceptConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.acceptConversationUseCase.execute(id, user.userId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return result.value;
  }

  @Get('conversations/:id')
  async getConversation(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    const result = await this.getMessagesUseCase.execute(id, user.userId);
    if (result.isLeft()) {
      return left(new AppError(result.value.code, result.value.message));
    }
    return { messages: result.value };
  }

  @Post('conversations/:id/messages')
  @HttpCode(HttpStatus.CREATED)
  async sendMessage(
    @Param('id') id: string,
    @Body() body: { content: string },
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
