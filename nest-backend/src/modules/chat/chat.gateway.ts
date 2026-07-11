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
import { JwtTokenValidatorService } from '@/shared/auth/jwt-token-validator.service';
import { ConversationRepository } from './domain/repositories/conversation.repository';
import { SendMessageUseCase } from './usecases/send-message.usecase';
import { ChatThreadAccessService } from './services/chat-thread-access.service';
import { NotificationService } from '../notifications/services/notification.service';
import { BlockRepository } from '@/modules/users/domain/repositories/block.repository';

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
    private conversationRepository: ConversationRepository,
    private sendMessageUseCase: SendMessageUseCase,
    private threadAccess: ChatThreadAccessService,
    private notificationService: NotificationService,
    private blockRepository: BlockRepository,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token || client.handshake.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        client.disconnect();
        return;
      }

      const payload = await this.tokenValidator.verifyAndValidate(token, ['access']);
      this.connectedUsers.set(client.id, { userId: payload.userId, email: payload.email });
      this.logger.log(`Client connected: ${client.id}, userId: ${payload.userId}`);
    } catch (error) {
      this.logger.error('WebSocket authentication failed', error);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
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
    @MessageBody() data: { conversationId: string; content: string },
  ) {
    const user = this.connectedUsers.get(client.id);
    if (!user) return { error: 'Unauthorized' };

    const message = await this.sendMessage(user.userId, data.conversationId, data.content);

    if (message) {
      this.server.to(`conversation:${data.conversationId}`).emit('new_message', message);
    }

    return { event: 'message_sent', data: message };
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

  private async sendMessage(userId: string, conversationId: string, content: string) {
    const result = await this.sendMessageUseCase.execute({ senderId: userId, conversationId, content });
    if (result.isLeft()) {
      return null;
    }

    const convResult = await this.conversationRepository.findDirectConversationById(conversationId);
    if (convResult.isLeft() || !convResult.value) return null;

    const conversation = convResult.value;

    const otherUserId = conversation.user1Id === userId ? conversation.user2Id : conversation.user1Id;
    const resultValue = result.value;

    const senderName = await this.getSenderName(userId);
    await this.notificationService.notifyNewMessage(otherUserId, senderName, conversationId);

    return resultValue;
  }

  private async getSenderName(userId: string): Promise<string> {
    const userResult = await this.conversationRepository.findUserById(userId);
    if (userResult.isLeft() || !userResult.value) return 'Alguém';
    return userResult.value.displayName || 'Alguém';
  }
}
