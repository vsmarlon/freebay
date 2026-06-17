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
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    extraData?: Record<string, string>;
  }) {
    const notification = await this.prisma.notification.create({
      data: {
        userId: data.userId,
        type: data.type,
        title: data.title,
        body: data.body,
        data: (data.extraData ?? {}) as Prisma.InputJsonValue,
      },
    });

    await this.fcm.sendNotification(data.userId, data.title, data.body, data.extraData);

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

  async notifyNewMessage(userId: string, senderName: string, conversationId: string) {
    await this.create({
      userId,
      type: 'MESSAGE',
      title: 'Nova mensagem',
      body: `${senderName} enviou uma mensagem`,
      extraData: { type: 'MESSAGE', action: 'chat', conversationId },
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
}
