import { Module } from '@nestjs/common';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { PrismaConversationPreferenceRepository } from '../data/repositories/conversation-preference-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
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
import { UrlSafetyService } from '../services/url-safety.service';
import { DeleteMessageUseCase } from './delete-message.usecase';
import { ToggleReactionUseCase } from './toggle-reaction.usecase';
import { ToggleStarUseCase } from './toggle-star.usecase';
import { GetStarredMessagesUseCase } from './get-starred-messages.usecase';
import { GetConversationMediaUseCase } from './get-conversation-media.usecase';
import { VerifyUrlSafetyUseCase } from './verify-url-safety.usecase';
import { ForwardMessagesUseCase } from './forward-messages.usecase';
import { MarkAsReadUseCase } from './mark-as-read.usecase';

@Module({
  providers: [
    MarkAsReadUseCase,
    ConversationDatabaseRepository,
    PrismaConversationPreferenceRepository,
    ChatThreadAccessService,
    PrismaBlockRepository,
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
    UrlSafetyService,
    DeleteMessageUseCase,
    ToggleReactionUseCase,
    ToggleStarUseCase,
    GetStarredMessagesUseCase,
    GetConversationMediaUseCase,
    VerifyUrlSafetyUseCase,
    ForwardMessagesUseCase,
  ],
  exports: [
    MarkAsReadUseCase,
    ConversationDatabaseRepository,
    ChatThreadAccessService,
    PrismaBlockRepository,
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
    UrlSafetyService,
    DeleteMessageUseCase,
    ToggleReactionUseCase,
    ToggleStarUseCase,
    GetStarredMessagesUseCase,
    GetConversationMediaUseCase,
    VerifyUrlSafetyUseCase,
    ForwardMessagesUseCase,
  ],
})
export class ChatUseCasesModule {}

