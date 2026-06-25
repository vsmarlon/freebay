import { Module } from '@nestjs/common';
import { ChatController } from './chat.controller';
import { ChatGateway } from './chat.gateway';
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
import { PrismaConversationPreferenceRepository } from './repositories/conversation-preference.repository';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { UsersModule } from '@/modules/users/users.module';
import { OrdersModule } from '@/modules/orders/orders.module';

@Module({
  imports: [UsersModule, OrdersModule],
  controllers: [ChatController],
  providers: [
    ChatGateway,
    SendMessageUseCase,
    GetConversationsUseCase,
    GetMessagesUseCase,
    StartConversationUseCase,
    AcceptConversationUseCase,
    GetUnifiedConversationsUseCase,
    ArchiveConversationUseCase,
    DeleteConversationUseCase,
    SetConversationThemeUseCase,
    SetConversationBackgroundUseCase,
    PrismaConversationPreferenceRepository,
    PrismaService,
  ],
})
export class ChatModule {}
