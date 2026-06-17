import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import type { Messaging } from 'firebase-admin/messaging';

@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private messaging: Messaging | null = null;

  constructor(
    private config: ConfigService,
    private prisma: PrismaService,
  ) {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      const projectId = this.config.get('FIREBASE_PROJECT_ID');
      const privateKey = this.config.get('FIREBASE_PRIVATE_KEY');
      const clientEmail = this.config.get('FIREBASE_CLIENT_EMAIL');

      if (!projectId || !privateKey || !clientEmail) {
        this.logger.log('Firebase credentials not configured, FCM disabled');
        return;
      }

      if (!getApps().length) {
        initializeApp({
          credential: cert({
            projectId,
            privateKey: privateKey.replace(/\\n/g, '\n'),
            clientEmail,
          }),
        });
      }

      this.messaging = getMessaging();
      this.logger.log('Firebase FCM initialized');
    } catch (error) {
      this.logger.error('Failed to initialize Firebase:', error);
    }
  }

  async sendNotification(userId: string, title: string, body: string, data?: Record<string, string>) {
    if (!this.messaging) {
      this.logger.log('FCM not initialized, skipping notification');
      return;
    }

    try {
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (!user?.fcmToken) {
        return;
      }

      await this.messaging.send({
        token: user.fcmToken,
        notification: { title, body },
        data,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
    } catch (error) {
      this.logger.error(`FCM sendNotification error for user ${userId}:`, error);
    }
  }

  async notifyPaymentReceived(userId: string, amount: number) {
    await this.sendNotification(
      userId,
      'Pagamento Recebido!',
      `Você recebeu R$ ${(amount / 100).toFixed(2)} da sua venda`,
      { type: 'PAYMENT', action: 'wallet' },
    );
  }

  async notifyNewMessage(userId: string, senderName: string) {
    await this.sendNotification(
      userId,
      'Nova mensagem',
      `${senderName} enviou uma mensagem`,
      { type: 'MESSAGE', action: 'chat' },
    );
  }

  async notifyNewFollower(userId: string, followerName: string) {
    await this.sendNotification(
      userId,
      'Novo seguidores',
      `${followerName} começou a seguir você`,
      { type: 'FOLLOW', action: 'profile' },
    );
  }

  async notifyOrderStatus(userId: string, orderId: string, status: string) {
    const statusMessages: Record<string, string> = {
      CONFIRMED: 'Seu pedido foi confirmado!',
      DELIVERED: 'Seu pedido foi entregue!',
      COMPLETED: 'Pedido concluído!',
      DISPUTE: 'Uma disputa foi aberta no seu pedido',
    };

    await this.sendNotification(
      userId,
      'Atualização do pedido',
      statusMessages[status] || `Pedido ${orderId}: ${status}`,
      { type: 'ORDER', action: 'orders', orderId },
    );
  }
}
