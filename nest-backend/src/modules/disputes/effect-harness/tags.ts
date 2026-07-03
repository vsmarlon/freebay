import { Context } from 'effect';
import { PrismaClient } from '@prisma/client';

export interface NotificationServiceShape {
  notifyDispute(userId: string, disputeId: string, message: string): Promise<void>;
  notifyOrderStatus(userId: string, orderId: string, status: string): Promise<void>;
  create(data: {
    userId: string;
    type: string;
    title: string;
    body: string;
    extraData?: Record<string, string>;
  }): Promise<{ id: string }>;
}

export class PrismaTag extends Context.Tag('PrismaTag')<PrismaTag, PrismaClient>() {}

export class NotificationTag extends Context.Tag('NotificationTag')<NotificationTag, NotificationServiceShape>() {}
