import { Module } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaConversationPreferenceRepository } from '../repositories/conversation-preference.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { BlockRepository } from '@/modules/users/repositories/block.repository';
import { SendMessageUseCase } from './send-message.usecase';
import { GetConversationsUseCase } from './get-conversations.usecase';
import { GetMessagesUseCase } from './get-messages.usecase';
import { StartConversationUseCase } from './start-conversation.usecase';
import { AcceptConversationUseCase } from './accept-conversation.usecase';
import { GetUnifiedConversationsUseCase } from './get-unified-conversations.usecase';
import { ArchiveConversationUseCase } from './archive-conversation.usecase';
import { DeleteConversationUseCase } from './delete-conversation.usecase';
import { SetConversationThemeUseCase } from './set-conversation-theme.usecase';
import { SetConversationBackgroundUseCase } from './set-conversation-background.usecase';

@Module({
  providers: [
    { provide: PrismaClient, useExisting: PrismaService },
    { provide: ConversationRepository, useClass: ConversationDatabaseRepository },
    PrismaConversationPreferenceRepository,
    ChatThreadAccessService,
    BlockRepository,
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
  ],
  exports: [
    ConversationRepository,
    ChatThreadAccessService,
    BlockRepository,
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
  ],
})
export class ChatUseCasesModule {}
