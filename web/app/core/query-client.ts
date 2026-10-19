export const userKey = (userId: string, feature: string, ...parts: unknown[]) => ['user', userId, feature, ...parts] as const;
