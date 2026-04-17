import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

@Injectable()
export class FcmService {
  private firebaseConfig: Record<string, string> | null = null;
  private messaging: Record<string, unknown> | null = null;
  private initialized = false;

  constructor(
    private config: ConfigService,
    private prisma: PrismaService,
  ) {
    this.initializeFirebase();
  }

  private async initializeFirebase() {
    try {
      const projectId = this.config.get('FIREBASE_PROJECT_ID');
      const privateKey = this.config.get('FIREBASE_PRIVATE_KEY');
      const clientEmail = this.config.get('FIREBASE_CLIENT_EMAIL');

      if (!projectId || !privateKey || !clientEmail) {
        console.log('Firebase credentials not configured, FCM disabled');
        return;
      }

      this.initialized = true;
      console.log('Firebase FCM initialized');
    } catch (error) {
      console.error('Failed to initialize Firebase:', error);
    }
  }

  async sendNotification(userId: string, title: string, body: string, _data?: Record<string, string>) {
    if (!this.initialized) {
      console.log('FCM not initialized, skipping notification');
      return;
    }

    try {
      const user = await this.prisma.user.findUnique({ where: { id: userId } });
      if (!user?.fcmToken) {
        return;
      }

      console.log(`[FCM] Would send to ${userId}: ${title} - ${body}`);
    } catch (error) {
      console.error('FCM sendNotification error:', error);
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
