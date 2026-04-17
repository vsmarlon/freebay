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
import { JwtService } from '@nestjs/jwt';

interface AuthenticatedUser {
  userId: string;
  email: string;
}

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private connectedUsers = new Map<string, AuthenticatedUser>();

  constructor(private jwtService: JwtService) {}

  handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token || client.handshake.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token);
      this.connectedUsers.set(client.id, { userId: payload.userId, email: payload.email });
      console.log(`Client connected: ${client.id}, userId: ${payload.userId}`);
    } catch (error) {
      console.error('WebSocket authentication failed:', error);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    this.connectedUsers.delete(client.id);
    console.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('join_conversation')
  handleJoinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { conversationId: string },
  ) {
    const user = this.connectedUsers.get(client.id);
    if (!user) return;

    client.join(`conversation:${data.conversationId}`);
    console.log(`User ${user.userId} joined conversation ${data.conversationId}`);
    
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
    return { id: `temp-${Date.now()}`, conversationId, senderId: userId, content, createdAt: new Date() };
  }
}
