export const preferenceKeys = ['orders', 'follows', 'messages', 'disputes'] as const;
export type PreferenceKey = typeof preferenceKeys[number];
export type NotificationPreferences = Partial<Record<PreferenceKey, boolean>>;

export function parseNotificationPreferences(value: unknown): NotificationPreferences {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  const preferences: NotificationPreferences = {};
  for (const [key, enabled] of Object.entries(value)) {
    const supported = preferenceKeys.find((candidate) => candidate === key);
    if (supported && typeof enabled === 'boolean') preferences[supported] = enabled;
  }
  return preferences;
}
