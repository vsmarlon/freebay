export function withoutPinMetadata(metadata: Record<string, unknown> | null): Record<string, unknown> | null {
  if (!metadata) return null;
  return Object.fromEntries(Object.entries(metadata).filter(([key]) => !['pinned', 'pinnedBy', 'pinnedAt'].includes(key)));
}
