import { Notification } from '@prisma/client';

export interface GetNotificationsInput {
  userId: string;
  limit?: number;
}

export type GetNotificationsOutput = Notification[];

export interface MarkAsReadInput {
  notificationId: string;
  userId: string;
}

export interface MarkAsReadOutput {
  marked: boolean;
}

export interface RegisterFcmTokenInput {
  userId: string;
  fcmToken: string;
}

export interface RegisterFcmTokenOutput {
  registered: boolean;
}
