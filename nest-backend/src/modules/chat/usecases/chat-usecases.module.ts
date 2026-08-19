import { Module } from '@nestjs/common';
import { ConversationRepository } from '../domain/repositories/conversation.repository';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ConversationPreferenceRepository } from '../domain/repositories/conversation-preference.repository';
import { PrismaConversationPreferenceRepository } from '../data/repositories/conversation-preference-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { BlockRepository } from '@/modules/users/domain/repositories/block.repository';
import { PrismaBlockRepository } from '@/modules/users/data/repositories/block-database.repository';
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
import { OgScraperService } from '../services/og-scraper.service';
import { DeleteMessageUseCase } from './delete-message.usecase';
import { ToggleReactionUseCase } from './toggle-reaction.usecase';
import { GetConversationMediaUseCase } from './get-conversation-media.usecase';

@Module({
  providers: [
    { provide: ConversationRepository, useClass: ConversationDatabaseRepository },
    PrismaConversationPreferenceRepository,
    { provide: ConversationPreferenceRepository, useExisting: PrismaConversationPreferenceRepository },
    ChatThreadAccessService,
    PrismaBlockRepository,
    { provide: BlockRepository, useExisting: PrismaBlockRepository },
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
    OgScraperService,
    DeleteMessageUseCase,
    ToggleReactionUseCase,
    GetConversationMediaUseCase,
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
    OgScraperService,
    DeleteMessageUseCase,
    ToggleReactionUseCase,
    GetConversationMediaUseCase,
  ],
})
export class ChatUseCasesModule {}
