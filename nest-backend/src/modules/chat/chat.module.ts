import { Module } from '@nestjs/common';
import { ChatController } from './chat.controller';
import { ChatGateway } from './chat.gateway';
import {
  SendMessageUseCase,
  GetConversationsUseCase,
  GetMessagesUseCase,
  StartConversationUseCase,
  AcceptConversationUseCase,
} from './usecases/chat.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Module({
  controllers: [ChatController],
  providers: [
    ChatGateway,
    SendMessageUseCase,
    GetConversationsUseCase,
    GetMessagesUseCase,
    StartConversationUseCase,
    AcceptConversationUseCase,
    PrismaService,
  ],
})
export class ChatModule {}
