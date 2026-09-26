import { Logger } from '@nestjs/common';
import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtTokenType } from '@/shared/core/types';
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { ConversationDatabaseRepository } from './data/repositories/conversation-database.repository';
import { redactReplySummary } from './mappers/conversation.mapper';
import { SendMessageUseCase } from './usecases/send-message.usecase';
import { DeleteMessageUseCase } from './usecases/delete-message.usecase';
import { ToggleReactionUseCase } from './usecases/toggle-reaction.usecase';
import { ChatThreadAccessService } from './services/chat-thread-access.service';
import { NotificationService } from '../notifications/services/notification.service';
import { PrismaBlockRepository } from '@/modules/users/data/repositories/block-database.repository';

interface AuthenticatedUser {
  userId: string;
  email?: string;
}

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  private readonly logger = new Logger(ChatGateway.name);

  @WebSocketServer()
  server: Server;

  private connectedUsers = new Map<string, AuthenticatedUser>();
  constructor(
    private tokenValidator: JwtTokenValidatorService,
    private conversationRepository: ConversationDatabaseRepository,
    private sendMessageUseCase: SendMessageUseCase,
    private deleteMessageUseCase: DeleteMessageUseCase,
    private toggleReactionUseCase: ToggleReactionUseCase,
    private threadAccess: ChatThreadAccessService,
    private notificationService: NotificationService,
    private blockRepository: PrismaBlockRepository,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token || client.handshake.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        client.disconnect();
        return;
      }

      const payload = await this.tokenValidator.verifyAndValidate(token, [JwtTokenType.ACCESS]);
      this.connectedUsers.set(client.id, { userId: payload.userId, email: payload.email });
      this.logger.log(`Client connected: ${client.id}, userId: ${payload.userId}`);

      client.broadcast.emit('user_online', { userId: payload.userId, lastSeenAt: null });
    } catch (error) {
      this.logger.error('WebSocket authentication failed', error);
      client.disconnect();
    }
  }

  async handleDisconnect(client: Socket) {
    const user = this.connectedUsers.get(client.id);
    if (user) {
      const now = new Date();
      client.broadcast.emit('user_offline', { userId: user.userId, lastSeenAt: now.toISOString() });
    }
    this.connectedUsers.delete(client.id);
    this.logger.log(`Client disconnected: ${client.id}`);
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

    if (blockedByOther || userBlockedOther) {
      return { error: 'You cannot join this conversation' };
    }

    client.join(`conversation:${data.conversationId}`);
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

    client.leave(`conversation:${data.conversationId}`);
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

    client.to(`conversation:${data.conversationId}`).emit('user_typing', { userId: user.userId });
  }

  @SubscribeMessage('typing_stop')
  handleTypingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const user = this.connectedUsers.get(client.id);
    if (!user) return;

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

    try {
      await this.notificationService.notifyNewMessage(
        resultValue.recipientId,
        resultValue.senderName,
        conversationId,
      );
    } catch (error) {
      this.logger.warn(`Chat notification failed: ${String(error)}`);
    }

    return { ...resultValue.message, replyTo };
  }
}
