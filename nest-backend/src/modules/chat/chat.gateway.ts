import { Logger } from '@nestjs/common';
import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayInit,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Namespace, Socket } from 'socket.io';
import { JwtTokenType } from '@/shared/core/types';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { ConversationDatabaseRepository } from './data/repositories/conversation-database.repository';
import { redactReplySummary } from './dtos/conversation-response';
import { SendMessageUseCase } from './usecases/send-message.usecase';
import { DeleteMessageUseCase } from './usecases/delete-message.usecase';
import { ToggleReactionUseCase } from './usecases/toggle-reaction.usecase';
import { ChatThreadAccessService } from './services/chat-thread-access.service';
import { PrismaBlockRepository } from '@/modules/users/data/repositories/block-database.repository';

interface AuthenticatedUser {
  userId: string;
  email?: string;
}

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(ChatGateway.name);

  @WebSocketServer()
  server: Namespace;

  private connectedUsers = new Map<string, AuthenticatedUser>();
  private authenticatedSockets = new WeakMap<Socket, AuthenticatedUser>();
  private joinedRooms = new Map<string, Set<string>>();
  constructor(
    private tokenValidator: JwtTokenValidatorService,
    private conversationRepository: ConversationDatabaseRepository,
    private sendMessageUseCase: SendMessageUseCase,
    private deleteMessageUseCase: DeleteMessageUseCase,
    private toggleReactionUseCase: ToggleReactionUseCase,
    private threadAccess: ChatThreadAccessService,
    private blockRepository: PrismaBlockRepository,
  ) {}

  afterInit(namespace: Namespace) {
    namespace.use(async (client, next) => {
      try {
        const token = client.handshake.auth.token || client.handshake.headers.authorization?.replace('Bearer ', '');
        if (!token) return next(new Error('jwt unauthorized'));
        const payload = await this.tokenValidator.verifyAndValidate(token, [JwtTokenType.ACCESS]);
        this.authenticatedSockets.set(client, { userId: payload.userId, email: payload.email });
        next();
      } catch (error) {
        this.logger.warn(`WebSocket authentication failed: ${String(error)}`);
        next(new Error('jwt unauthorized'));
      }
    });
  }

  handleConnection(client: Socket) {
    const user = this.authenticatedSockets.get(client);
    if (!user) return client.disconnect(true);
    this.connectedUsers.set(client.id, user);
    this.logger.log(`Client connected: ${client.id}, userId: ${user.userId}`);

  }

  async handleDisconnect(client: Socket) {
    const user = this.connectedUsers.get(client.id);
    if (user) {
      for (const room of this.joinedRooms.get(client.id) ?? []) {
        if (!this.hasOtherDeviceInRoom(user.userId, room, client.id)) {
          this.server.to(room).emit('user_offline', { userId: user.userId, lastSeenAt: new Date().toISOString() });
        }
      }
    }
    this.joinedRooms.delete(client.id);
    this.connectedUsers.delete(client.id);
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  private hasOtherDeviceInRoom(userId: string, room: string, clientId: string): boolean {
    return [...(this.server.adapter.rooms.get(room) ?? [])]
      .some((id) => id !== clientId && this.connectedUsers.get(id)?.userId === userId);
  }

  @SubscribeMessage('join_conversation')
  async handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const user = this.connectedUsers.get(client.id);
    if (!user) return;

    const resolved = await this.threadAccess.resolveThread(user.userId, data.conversationId);
    if (resolved.isLeft()) {
      return { error: 'Not a participant of this conversation' };
    }

    const { otherUserId } = resolved.value;

    const [blockedByOtherResult, userBlockedOtherResult] = await Promise.all([
      this.blockRepository.isBlocked(otherUserId, user.userId),
      this.blockRepository.isBlocked(user.userId, otherUserId),
    ]);

    const blockedByOther = !blockedByOtherResult.isLeft() && blockedByOtherResult.value;
    const userBlockedOther = !userBlockedOtherResult.isLeft() && userBlockedOtherResult.value;

    if (blockedByOtherResult.isLeft() || userBlockedOtherResult.isLeft() || blockedByOther || userBlockedOther) {
      return { error: 'You cannot join this conversation' };
    }

    const room = `conversation:${data.conversationId}`;
    if (client.rooms.has(room)) return { event: 'joined', data: { conversationId: data.conversationId } };
    const alreadyOnline = this.hasOtherDeviceInRoom(user.userId, room, client.id);
    const occupants = [...(this.server.adapter.rooms.get(room) ?? [])]
      .map((id) => this.connectedUsers.get(id)?.userId)
      .filter((id): id is string => !!id && id !== user.userId);
    client.join(room);
    const rooms = this.joinedRooms.get(client.id) ?? new Set<string>();
    rooms.add(room);
    this.joinedRooms.set(client.id, rooms);
    for (const userId of new Set(occupants)) {
      client.emit('user_online', { userId, lastSeenAt: null });
    }
    if (!alreadyOnline) client.to(room).emit('user_online', { userId: user.userId, lastSeenAt: null });
    this.logger.log(`User ${user.userId} joined conversation ${data.conversationId}`);

    return { event: 'joined', data: { conversationId: data.conversationId } };
  }

  @SubscribeMessage('leave_conversation')
  handleLeaveConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const user = this.connectedUsers.get(client.id);
    if (!user) return;

    const room = `conversation:${data.conversationId}`;
    if (!client.rooms.has(room)) return;
    client.leave(room);
    this.joinedRooms.get(client.id)?.delete(room);
    if (!this.hasOtherDeviceInRoom(user.userId, room, client.id)) {
      client.to(room).emit('user_offline', { userId: user.userId, lastSeenAt: new Date().toISOString() });
    }
    return { event: 'left', data: { conversationId: data.conversationId } };
  }

  @SubscribeMessage('send_message')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; content: string; replyToId?: string },
  ) {
    const user = this.connectedUsers.get(client.id);
    if (!user) return { error: 'Unauthorized' };

    const message = await this.sendMessage(
      user.userId,
      data.conversationId,
      data.content,
      data.replyToId,
    );

    if (message) {
      this.server.to(`conversation:${data.conversationId}`).emit('new_message', message);
    }

    return { event: 'message_sent', data: message };
  }

  broadcastNewMessage(conversationId: string, message: unknown) {
    this.server.to(`conversation:${conversationId}`).emit('new_message', message);
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const user = this.connectedUsers.get(client.id);
    if (!user) return;

    if (!client.rooms.has(`conversation:${data.conversationId}`)) return;
    client.to(`conversation:${data.conversationId}`).emit('user_typing', { userId: user.userId });
  }

  @SubscribeMessage('typing_stop')
  handleTypingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const user = this.connectedUsers.get(client.id);
    if (!user) return;

    if (!client.rooms.has(`conversation:${data.conversationId}`)) return;
    client.to(`conversation:${data.conversationId}`).emit('user_stopped_typing', { userId: user.userId });
  }

  @SubscribeMessage('delete_message')
  async handleDeleteMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; messageId: string },
  ) {
    const user = this.connectedUsers.get(client.id);
    if (!user) return { error: 'Unauthorized' };

    const result = await this.deleteMessageUseCase.execute({
      messageId: data.messageId,
      userId: user.userId,
      conversationId: data.conversationId,
    });
    if (result.isLeft()) return { error: result.value.message };

    this.server.to(`conversation:${data.conversationId}`).emit('message_deleted', { messageId: data.messageId });
    return { event: 'message_deleted' };
  }

  @SubscribeMessage('toggle_reaction')
  async handleToggleReaction(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string; messageId: string; emoji: string },
  ) {
    const user = this.connectedUsers.get(client.id);
    if (!user) return { error: 'Unauthorized' };

    const result = await this.toggleReactionUseCase.execute({
      userId: user.userId,
      messageId: data.messageId,
      emoji: data.emoji,
      conversationId: data.conversationId,
    });
    if (result.isLeft()) return { error: result.value.message };

    this.server.to(`conversation:${data.conversationId}`).emit('reaction_updated', {
      messageId: data.messageId,
      reactions: result.value.reactions,
    });
    return { event: 'reaction_updated', data: result.value };
  }

  private async sendMessage(
    userId: string,
    conversationId: string,
    content: string,
    replyToId?: string,
  ) {
    const result = await this.sendMessageUseCase.execute({
      senderId: userId,
      conversationId,
      content,
      replyToId,
    });
    if (result.isLeft()) {
      return null;
    }

    const resultValue = result.value;

    let replyTo = null;
    if (resultValue.message.replyToId) {
      const replyResult = await this.conversationRepository.findReplyToSummary(resultValue.message.replyToId);
      if (!replyResult.isLeft() && replyResult.value) {
        replyTo =
          replyResult.value.conversationId === resultValue.message.conversationId
            ? redactReplySummary(replyResult.value)
            : null;
      }
    }

    return { ...resultValue.message, replyTo };
  }
}
