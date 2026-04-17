import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/notifications',
})
export class NotificationsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private userSockets = new Map<string, Set<string>>();

  constructor(private jwtService: JwtService) {}

  handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token || client.handshake.headers.authorization?.replace('Bearer ', '');
      if (!token) {
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify(token);
      const userId = payload.userId;

      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId)!.add(client.id);

      console.log(`User ${userId} connected to notifications, total sockets: ${this.userSockets.get(userId)!.size}`);
    } catch (error) {
      console.error('Notifications WebSocket auth failed:', error);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    this.userSockets.forEach((sockets, userId) => {
      if (sockets.has(client.id)) {
        sockets.delete(client.id);
        if (sockets.size === 0) {
          this.userSockets.delete(userId);
        }
      }
    });
    console.log(`Client disconnected: ${client.id}`);
  }

  sendNotification(userId: string, notification: Record<string, unknown>) {
    const sockets = this.userSockets.get(userId);
    if (sockets) {
      sockets.forEach(socketId => {
        this.server.to(socketId).emit('notification', notification);
      });
    }
  }

  @SubscribeMessage('mark_read')
  handleMarkRead(@ConnectedSocket() client: Socket, @MessageBody() data: { notificationId: string }) {
    return { event: 'marked', data: { notificationId: data.notificationId } };
  }
}
