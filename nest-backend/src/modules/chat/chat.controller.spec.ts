import { Test } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { ChatController } from './chat.controller';
import { StartConversationUseCase } from './usecases/start-conversation.usecase';
import { GetUnifiedConversationsUseCase } from './usecases/get-unified-conversations.usecase';
import { GetConversationsUseCase } from './usecases/get-conversations.usecase';
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
import { ToggleStarUseCase } from './usecases/toggle-star.usecase';
import { GetStarredMessagesUseCase } from './usecases/get-starred-messages.usecase';
import { VerifyUrlSafetyUseCase } from './usecases/verify-url-safety.usecase';
import { ForwardMessagesUseCase } from './usecases/forward-messages.usecase';
import { MarkAsReadUseCase } from './usecases/mark-as-read.usecase';
import { ChatGateway } from './chat.gateway';
import { SendMessageDTO, StartConversationDTO, StartConversationOutput } from './dtos/chat.dto';
import { Either, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';

describe('ChatController.startConversation', () => {
  it('forwards the authenticated initiator, target, and optional product', async () => {
    const execute = jest.fn<
      Promise<Either<AppError, StartConversationOutput>>,
      [string, string, string?]
    >().mockResolvedValue(right({
      conversationId: 'conversation-1',
      status: 'PENDING',
      threadType: 'DIRECT',
      otherUser: { id: 'target-1', displayName: 'Target', avatarUrl: null },
      product: null,
    }));

    const module = await Test.createTestingModule({
      controllers: [ChatController],
      providers: [
        { provide: StartConversationUseCase, useValue: { execute } },
        { provide: GetUnifiedConversationsUseCase, useValue: {} },
        { provide: GetConversationsUseCase, useValue: {} },
        { provide: AcceptConversationUseCase, useValue: {} },
        { provide: GetMessagesUseCase, useValue: {} },
        { provide: GetConversationMediaUseCase, useValue: {} },
        { provide: SendMessageUseCase, useValue: {} },
        { provide: ArchiveConversationUseCase, useValue: {} },
        { provide: DeleteConversationUseCase, useValue: {} },
        { provide: SetConversationThemeUseCase, useValue: {} },
        { provide: SetConversationBackgroundUseCase, useValue: {} },
        { provide: DeleteMessageUseCase, useValue: {} },
        { provide: ToggleReactionUseCase, useValue: {} },
        { provide: ToggleStarUseCase, useValue: {} },
        { provide: GetStarredMessagesUseCase, useValue: {} },
        { provide: VerifyUrlSafetyUseCase, useValue: {} },
        { provide: ForwardMessagesUseCase, useValue: {} },
        { provide: MarkAsReadUseCase, useValue: {} },
        { provide: ChatGateway, useValue: {} },
        { provide: Reflector, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
      ],
    }).compile();
    const controller = module.get(ChatController);
    const productBody = {
      targetUserId: 'target-1',
      productId: 'product-1',
    } satisfies StartConversationDTO;
    const genericBody = { targetUserId: 'target-1' } satisfies StartConversationDTO;

    await controller.startConversation('initiator-1', productBody);
    await controller.startConversation('initiator-1', genericBody);

    expect(execute).toHaveBeenNthCalledWith(1, 'initiator-1', 'target-1', 'product-1');
    expect(execute).toHaveBeenNthCalledWith(2, 'initiator-1', 'target-1', undefined);
    expect('productId' in genericBody).toBe(false);
  });
});

describe('ChatController.sendMessage', () => {
  it('broadcasts the persisted message including its client id and location metadata', async () => {
    const message = {
      id: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'sender-1',
      clientMessageId: 'location-1',
      content: null,
      type: 'LOCATION',
      attachmentUrl: null,
      metadata: {
        latitude: 1,
        longitude: 2,
        accuracyMeters: 3,
        capturedAt: '2026-09-14T05:00:00.000Z',
      },
      replyToId: null,
      viewOnce: false,
      createdAt: new Date(),
    };
    const execute = jest.fn().mockResolvedValue(right({
      message,
      recipientId: 'recipient-1',
      senderName: 'Sender',
    }));
    const broadcastNewMessage = jest.fn();
    const module = await Test.createTestingModule({
      controllers: [ChatController],
      providers: [
        { provide: StartConversationUseCase, useValue: {} },
        { provide: GetUnifiedConversationsUseCase, useValue: {} },
        { provide: GetConversationsUseCase, useValue: {} },
        { provide: AcceptConversationUseCase, useValue: {} },
        { provide: GetMessagesUseCase, useValue: {} },
        { provide: GetConversationMediaUseCase, useValue: {} },
        { provide: SendMessageUseCase, useValue: { execute } },
        { provide: ArchiveConversationUseCase, useValue: {} },
        { provide: DeleteConversationUseCase, useValue: {} },
        { provide: SetConversationThemeUseCase, useValue: {} },
        { provide: SetConversationBackgroundUseCase, useValue: {} },
        { provide: DeleteMessageUseCase, useValue: {} },
        { provide: ToggleReactionUseCase, useValue: {} },
        { provide: ToggleStarUseCase, useValue: {} },
        { provide: GetStarredMessagesUseCase, useValue: {} },
        { provide: VerifyUrlSafetyUseCase, useValue: {} },
        { provide: ForwardMessagesUseCase, useValue: {} },
        { provide: MarkAsReadUseCase, useValue: {} },
        { provide: ChatGateway, useValue: { broadcastNewMessage } },
        { provide: Reflector, useValue: {} },
        { provide: JwtTokenValidatorService, useValue: {} },
      ],
    }).compile();
    const controller = module.get(ChatController);
    const body = {
      type: 'LOCATION',
      clientMessageId: 'location-1',
      metadata: message.metadata,
    } satisfies SendMessageDTO;

    const result = await controller.sendMessage('conversation-1', body, 'sender-1');

    expect(broadcastNewMessage).toHaveBeenCalledWith('conversation-1', message);
    expect(result).toEqual(message);
  });
});
