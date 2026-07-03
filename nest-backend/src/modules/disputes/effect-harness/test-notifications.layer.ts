import { Layer } from 'effect';
import { NotificationTag, NotificationServiceShape } from './tags';

export interface RecordedNotification {
  method: string;
  args: unknown[];
}

export const TestNotificationsLayer = (calls: RecordedNotification[]) =>
  Layer.sync(
    NotificationTag,
    () =>
      ({
        notifyDispute: (userId: string, disputeId: string, message: string) => {
          calls.push({ method: 'notifyDispute', args: [userId, disputeId, message] });
          return Promise.resolve();
        },
        notifyOrderStatus: (userId: string, orderId: string, status: string) => {
          calls.push({ method: 'notifyOrderStatus', args: [userId, orderId, status] });
          return Promise.resolve();
        },
        create: (data: {
          userId: string;
          type: string;
          title: string;
          body: string;
          extraData?: Record<string, string>;
        }) => {
          calls.push({ method: 'create', args: [data] });
          return Promise.resolve({ id: 'mock-notification-id' });
        },
      }) satisfies NotificationServiceShape,
  );
