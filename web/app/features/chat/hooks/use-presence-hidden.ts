import { useSyncExternalStore } from 'react';

// Hidden-presence is a per-user local preference keyed by conversation id, kept
// in localStorage with a legacy fallback key. A external snapshot store drives
// React through useSyncExternalStore, so reads and own writes never need
// component state.
const listeners = new Set<() => void>();
let snapshots: Map<string, boolean> | null = null;

function invalidate() {
  snapshots = null;
  for (const listener of listeners) listener();
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  // Re-read on cross-tab writes; our own writes notify explicitly.
  window.addEventListener('storage', invalidate);
  return () => { listeners.delete(listener); window.removeEventListener('storage', invalidate); };
}

function hiddenFor(userId: string, conversationId: string): boolean {
  if (!snapshots) snapshots = new Map();
  const key = `${userId}|${conversationId}`;
  const known = snapshots.get(key);
  if (known !== undefined) return known;
  let hidden = false;
  try {
    const saved = localStorage.getItem(`freebay.chat.presence-hidden.${userId}`);
    const legacy = saved === null ? localStorage.getItem(`freebay.chat.muted.${userId}`) : null;
    const parsed: unknown = JSON.parse(saved ?? legacy ?? '[]');
    hidden = Array.isArray(parsed) && parsed.includes(conversationId);
  } catch { hidden = false; /* fallback to hidden=false */ }
  snapshots.set(key, hidden);
  return hidden;
}

function storedIds(key: string, fallbackKey: string | null): string[] {
  try {
    const saved: unknown = JSON.parse(localStorage.getItem(key) ?? (fallbackKey ? localStorage.getItem(fallbackKey) : null) ?? '[]');
    return Array.isArray(saved) ? saved.filter((value): value is string => typeof value === 'string') : [];
  } catch { return []; }
}

export function usePresenceHidden(userId: string | undefined, conversationId: string) {
  const hidden = useSyncExternalStore(subscribe, () => (userId ? hiddenFor(userId, conversationId) : false), () => false);
  // Returns null when storage rejects the write; the caller surfaces the toast.
  const toggle = (): boolean | null => {
    if (!userId) return null;
    const key = `freebay.chat.presence-hidden.${userId}`;
    const current = hiddenFor(userId, conversationId);
    const ids = storedIds(key, `freebay.chat.muted.${userId}`);
    const next = current ? ids.filter((chatId) => chatId !== conversationId) : [...new Set([...ids, conversationId])];
    try {
      localStorage.setItem(key, JSON.stringify(next));
    } catch { return null; }
    invalidate();
    return !current;
  };
  return { hidden, toggle };
}
