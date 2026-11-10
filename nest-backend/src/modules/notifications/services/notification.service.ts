import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { FcmService } from '../fcm.service';
import { NotificationType, Prisma } from '@prisma/client';
import { NotificationsGateway } from '../notifications.gateway';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    private prisma: PrismaService,
    private fcm: FcmService,
    private notificationsGateway: NotificationsGateway,
  ) {}

  deliverPersisted(userId: string, id: string, type: NotificationType, data: Prisma.JsonValue | null): void {
    try {
      this.notificationsGateway.sendNotification(userId, { id, type, data });
      const pushData: Record<string, string> = { type, notificationId: id };
      if (typeof data === 'object' && data !== null && !Array.isArray(data)) {
        for (const [key, value] of Object.entries(data)) if (typeof value === 'string') pushData[key] = value;
      }
      void this.fcm.sendNotification(userId, 'Nova resposta', 'Há uma nova resposta na conversa', pushData);
    } catch (error) {
      this.logger.warn('Failed to deliver persisted notification', error);
    }
  }

  async create(data: {
    id?: string;
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    extraData?: Record<string, string>;
  }, options?: { suppressPush?: boolean }) {
    const extraData = { ...data.extraData, type: data.type };
    const notification = await this.prisma.notification.create({
      data: {
        id: data.id,
        userId: data.userId,
        type: data.type,
        title: data.title,
        body: data.body,
        data: extraData,
      },
    }).catch((error: unknown) => {
      // A persisted message owns one notification, even across HTTP/socket retries.
      if (data.id && error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') return null;
      throw error;
    });
    if (!notification) return null;

    try {
      this.notificationsGateway.sendNotification(data.userId, { id: notification.id, type: notification.type });
    } catch (error) {
      this.logger.warn('Failed to emit notification invalidation', error);
    }

    if (!options?.suppressPush) {
      await this.fcm.sendNotification(data.userId, data.title, data.body, extraData);
    }

    return notification;
  }

  async notifyPayment(ownerId: string, amount: number) {
    await this.create({
      userId: ownerId,
      type: 'PAYMENT',
      title: 'Pagamento Recebido!',
      body: `Você recebeu R$ ${(amount / 100).toFixed(2)} da sua venda`,
      extraData: { type: 'PAYMENT', action: 'wallet' },
    });
  }

  async notifyNewMessage(userId: string, senderName: string, conversationId: string, messageId: string, options?: { suppressPush?: boolean }) {
    await this.create({
      id: messageId,
      userId,
      type: 'MESSAGE',
      title: 'Nova mensagem',
      body: `${senderName} enviou uma mensagem`,
      extraData: { type: 'MESSAGE', action: 'chat', conversationId, messageId },
    }, options);
  }

  async notifyNewFollower(userId: string, followerName: string, followerId: string) {
    await this.create({
      userId,
      type: 'FOLLOW',
      title: 'Novo seguidor',
      body: `${followerName} começou a seguir você`,
      extraData: { type: 'FOLLOW', action: 'profile', userId: followerId },
    });
  }

  async notifyOrderStatus(userId: string, orderId: string, status: string) {
    const statusMessages: Record<string, string> = {
      CONFIRMED: 'Seu pedido foi confirmado!',
      SHIPPED: 'Seu pedido foi enviado!',
      DELIVERED: 'Seu pedido foi entregue!',
      COMPLETED: 'Pedido concluído!',
      CANCELLED: 'Seu pedido foi cancelado',
      DISPUTED: 'Uma disputa foi aberta no seu pedido',
    };

    await this.create({
      userId,
      type: 'ORDER',
      title: 'Atualização do pedido',
      body: statusMessages[status] || `Pedido: ${status}`,
      extraData: { type: 'ORDER', action: 'orders', orderId },
    });
  }

  async notifyDispute(userId: string, disputeId: string, orderId: string, message: string) {
    await this.create({
      userId,
      type: 'DISPUTE',
      title: 'Disputa',
      body: message,
      extraData: { type: 'DISPUTE', action: 'disputes', disputeId, orderId },
    });
  }

  async notifyMention(userId: string, body: string, postId: string, commentId?: string) {
    await this.create({
      userId,
      type: 'MENTION',
      title: 'Menção',
      body,
      extraData: {
        type: 'MENTION',
        action: 'post',
        postId,
        ...(commentId ? { commentId } : {}),
      },
    });
  }
}
