import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationDatabaseRepository } from './data/repositories/notification-database.repository';
import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import type { Messaging } from 'firebase-admin/messaging';

const PUSH_PREFERENCES: Readonly<Partial<Record<string, string>>> = {
  MESSAGE: 'messages', FOLLOW: 'follows', ORDER: 'orders', PAYMENT: 'orders', DISPUTE: 'disputes',
};

@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private messaging: Messaging | null = null;

  constructor(
    private config: ConfigService,
    private readonly notifications: NotificationDatabaseRepository,
  ) {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      const projectId = this.config.get<string>('FIREBASE_PROJECT_ID');
      const privateKey = this.config.get<string>('FIREBASE_PRIVATE_KEY');
      const clientEmail = this.config.get<string>('FIREBASE_CLIENT_EMAIL');

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
      const targets = await this.notifications.findPushTargets(userId);
      if (targets.isLeft()) {
        this.logger.warn('Failed to load push targets');
        return;
      }
      const user = targets.value;
      if (!user || user.deletedAt || user.deletionRequestedAt) return;
      const preference = PUSH_PREFERENCES[data?.type ?? ''];
      const prefs = user.notificationPrefs;
      if (preference && prefs && typeof prefs === 'object' && !Array.isArray(prefs) && prefs[preference] === false) return;

      const allTokens = user.pushDevices.map((device) => device.token);
      for (let offset = 0; offset < allTokens.length; offset += 500) {
        const tokens = allTokens.slice(offset, offset + 500);
        const response = await this.messaging.sendEachForMulticast({
          tokens,
          notification: { title, body },
          data,
          android: { priority: 'high', notification: { channelId: 'freebay_notifications' } },
          apns: { payload: { aps: { sound: 'default' } } },
        });
        const invalidTokens = response.responses.flatMap((result, index) =>
          result.error && ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(result.error.code) ? [tokens[index]] : []);
        if (response.failureCount) this.logger.warn(`FCM rejected ${response.failureCount} of ${tokens.length} deliveries`);
        if (invalidTokens.length) {
          const cleanup = await this.notifications.removeInvalidPushTokens(userId, invalidTokens);
          if (cleanup.isLeft()) this.logger.warn('Failed to remove invalid push tokens');
        }
      }
    } catch (error) {
      this.logger.error(`FCM sendNotification error for user ${userId}:`, error);
    }
  }

}
