import { useSyncExternalStore } from 'react';

export type Theme = 'light' | 'dark' | 'system';
type Prefs = { theme: Theme; animatedBackground: boolean; feedSoundOn: boolean };

const key = 'freebay.preferences';
const fallback: Prefs = { theme: 'system', animatedBackground: true, feedSoundOn: false };
const listeners = new Set<() => void>();
let current: Prefs | null = null;
const darkQuery =
  typeof matchMedia === 'undefined' ? null : matchMedia('(prefers-color-scheme: dark)');

function readPrefs(): Prefs {
  try {
    const saved: unknown = JSON.parse(localStorage.getItem(key) ?? '{}');
    if (!saved || typeof saved !== 'object') return fallback;
    const next = { ...fallback };
    if (
      'theme' in saved &&
      (saved.theme === 'light' || saved.theme === 'dark' || saved.theme === 'system')
    )
      next.theme = saved.theme;
    if ('animatedBackground' in saved && typeof saved.animatedBackground === 'boolean')
      next.animatedBackground = saved.animatedBackground;
    if ('feedSoundOn' in saved && typeof saved.feedSoundOn === 'boolean')
      next.feedSoundOn = saved.feedSoundOn;
    return next;
  } catch {
    return fallback;
  }
}

function snapshot(): Prefs {
  if (!current) current = readPrefs();
  return current;
}

function serverSnapshot(): Prefs {
  return fallback;
}

function applyDocument(prefs: Prefs) {
  if (typeof document === 'undefined') return;
  const root = document.documentElement;
  root.dataset.theme =
    prefs.theme === 'system' ? (darkQuery?.matches ? 'dark' : 'light') : prefs.theme;
  root.dataset.aurora = prefs.animatedBackground ? 'on' : 'off';
}

function persist(prefs: Prefs) {
  if (typeof localStorage === 'undefined') return;
  try {
    localStorage.setItem(key, JSON.stringify(prefs));
  } catch {
    /* storage can be disabled */
  }
}

function notify() {
  for (const listener of listeners) listener();
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  const onChange = () => {
    if (current?.theme === 'system') applyDocument(snapshot());
    notify();
  };
  darkQuery?.addEventListener('change', onChange);
  return () => {
    listeners.delete(listener);
    darkQuery?.removeEventListener('change', onChange);
  };
}

function update(next: Prefs) {
  current = next;
  applyDocument(next);
  persist(next);
  notify();
}

export function PreferencesProvider({ children }: React.PropsWithChildren) {
  return children;
}
export function usePreferences() {
  const prefs = useSyncExternalStore(subscribe, snapshot, serverSnapshot);
  return {
    theme: prefs.theme,
    animatedBackground: prefs.animatedBackground,
    feedSoundOn: prefs.feedSoundOn,
    setTheme: (value: Theme) => update({ ...snapshot(), theme: value }),
    setAnimatedBackground: (value: boolean) => update({ ...snapshot(), animatedBackground: value }),
    setFeedSoundOn: (value: boolean) => update({ ...snapshot(), feedSoundOn: value }),
  };
}
