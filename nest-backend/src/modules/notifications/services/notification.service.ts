import { Injectable } from '@nestjs/common';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { FcmService } from '../fcm.service';
import { NotificationType, Prisma } from '@prisma/client';

@Injectable()
export class NotificationService {
  constructor(
    private prisma: PrismaService,
    private fcm: FcmService,
  ) {}

  async create(data: {
    id?: string;
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    extraData?: Record<string, string>;
  }) {
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

    await this.fcm.sendNotification(data.userId, data.title, data.body, extraData);

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

  async notifyNewMessage(userId: string, senderName: string, conversationId: string, messageId: string) {
    await this.create({
      id: messageId,
      userId,
      type: 'MESSAGE',
      title: 'Nova mensagem',
      body: `${senderName} enviou uma mensagem`,
      extraData: { type: 'MESSAGE', action: 'chat', conversationId, messageId },
    });
  }

  async notifyNewFollower(userId: string, followerName: string) {
    await this.create({
      userId,
      type: 'FOLLOW',
      title: 'Novo seguidor',
      body: `${followerName} começou a seguir você`,
      extraData: { type: 'FOLLOW', action: 'profile' },
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

  async notifyDispute(userId: string, disputeId: string, message: string) {
    await this.create({
      userId,
      type: 'DISPUTE',
      title: 'Disputa',
      body: message,
      extraData: { type: 'DISPUTE', action: 'disputes', disputeId },
    });
  }

  async notifyMention(userId: string, body: string, entityId: string) {
    await this.create({
      userId,
      type: 'MENTION',
      title: 'Menção',
      body,
      extraData: { type: 'MENTION', action: 'post', entityId },
    });
  }
}
