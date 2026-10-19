import { describe, expect, it } from 'vitest';
import { parseNotificationPreferences } from './notification-preferences';

describe('notification preferences response parsing', () => {
  it('keeps only the four backend-supported boolean preferences without inventing defaults', () => {
    expect(parseNotificationPreferences({ orders: false, follows: true, messages: true, disputes: false, marketing: true, messages2: 'yes' })).toEqual({ orders: false, follows: true, messages: true, disputes: false });
    expect(parseNotificationPreferences(undefined)).toEqual({});
    expect(parseNotificationPreferences(['orders', true])).toEqual({});
  });
});
