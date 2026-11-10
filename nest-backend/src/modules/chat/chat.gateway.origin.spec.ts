import { createServer, type Server as HttpServer } from 'node:http';
import { Server as SocketServer, type ServerOptions } from 'socket.io';
import { GATEWAY_OPTIONS } from '@nestjs/websockets/constants';
import { ChatGateway } from './chat.gateway';
import { Test } from '@nestjs/testing';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { ConversationDatabaseRepository } from './data/repositories/conversation-database.repository';
import { SendMessageUseCase } from './usecases/send-message.usecase';
import { DeleteMessageUseCase } from './usecases/delete-message.usecase';
import { ToggleReactionUseCase } from './usecases/toggle-reaction.usecase';
import { ChatThreadAccessService } from './services/chat-thread-access.service';
import { BlockDatabaseRepository } from '@/modules/users/data/repositories/block-database.repository';

function hasOriginOptions(value: unknown): value is Pick<ServerOptions, 'allowRequest' | 'cors'> {
  if (typeof value !== 'object' || value === null) return false;
  const validAllowRequest = !('allowRequest' in value) || typeof value.allowRequest === 'function';
  const cors = 'cors' in value ? value.cors : undefined;
  return validAllowRequest && (cors === undefined || (typeof cors === 'object' && cors !== null));
}

describe('ChatGateway origin handshake', () => {
  let httpServer: HttpServer | undefined;
  let io: SocketServer | undefined;

  afterEach(async () => {
    if (io) await new Promise<void>((resolve) => io?.close(() => resolve()));
    else if (httpServer?.listening) await new Promise<void>((resolve, reject) => httpServer?.close((error) => error ? reject(error) : resolve()));
    io = undefined;
    httpServer = undefined;
  });

  it('rejects an unlisted browser Origin at the Engine.IO handshake', async () => {
    const configured: unknown = Reflect.getMetadata(GATEWAY_OPTIONS, ChatGateway);
    const options = hasOriginOptions(configured) ? configured : {};
    httpServer = createServer();
    io = new SocketServer(httpServer, { allowRequest: options.allowRequest, cors: options.cors });
    await new Promise<void>((resolve, reject) => {
      httpServer?.once('error', reject);
      httpServer?.listen(0, '127.0.0.1', resolve);
    });
    const address = httpServer.address();
    if (!address || typeof address === 'string') throw new Error('Test server failed to bind');

    const response = await fetch(`http://127.0.0.1:${address.port}/socket.io/?EIO=4&transport=polling`, {
      headers: { Origin: 'https://attacker.example' },
    });

    expect(response.status).toBe(403);
    await response.body?.cancel();
  });
});

describe('ChatGateway read invalidation', () => {
  it('emits the opaque read event only to the conversation room', async () => {
    const module = await Test.createTestingModule({
      providers: [
        ChatGateway,
        { provide: JwtTokenValidatorService, useValue: {} },
        { provide: ConversationDatabaseRepository, useValue: {} },
        { provide: SendMessageUseCase, useValue: {} },
        { provide: DeleteMessageUseCase, useValue: {} },
        { provide: ToggleReactionUseCase, useValue: {} },
        { provide: ChatThreadAccessService, useValue: {} },
        { provide: BlockDatabaseRepository, useValue: {} },
      ],
    }).compile();
    const gateway = module.get(ChatGateway);
    const emit = jest.fn();
    const to = jest.fn().mockReturnValue({ emit });
    Object.defineProperty(gateway, 'server', { value: { to } });

    gateway.broadcastMessagesRead('conversation-1', 'reader-1');

    expect(to).toHaveBeenCalledWith('conversation:conversation-1');
    expect(emit).toHaveBeenCalledWith('messages_read', {
      conversationId: 'conversation-1',
      readerId: 'reader-1',
    });
  });
});
