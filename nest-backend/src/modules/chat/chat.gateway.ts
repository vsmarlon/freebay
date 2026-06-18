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
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { SendMessageUseCase } from './usecases/chat.usecase';
import { NotificationService } from '../notifications/services/notification.service';

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
    private prisma: PrismaService,
    private sendMessageUseCase: SendMessageUseCase,
    private notificationService: NotificationService,
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

    const conversation = await this.prisma.directConversation.findUnique({
      where: { id: data.conversationId },
    });

    if (!conversation || (conversation.user1Id !== user.userId && conversation.user2Id !== user.userId)) {
      return { error: 'Not a participant of this conversation' };
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

    const conversation = await this.prisma.directConversation.findUnique({
      where: { id: conversationId },
      include: {
        user1: { select: { id: true, displayName: true } },
        user2: { select: { id: true, displayName: true } },
      },
    });

    if (conversation) {
      const otherUserId = conversation.user1Id === userId ? conversation.user2Id : conversation.user1Id;
      const senderName = conversation.user1Id === userId ? conversation.user1.displayName : conversation.user2.displayName;
      await this.notificationService.notifyNewMessage(otherUserId, senderName, conversationId);
    }

    return result.value;
  }
}
