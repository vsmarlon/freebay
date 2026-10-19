import { createContext, useContext, useEffect, useState } from 'react';
export type Theme = 'light' | 'dark' | 'system';
type Preferences = { theme: Theme; setTheme: (value: Theme) => void; animatedBackground: boolean; setAnimatedBackground: (value: boolean) => void };
const Context = createContext<Preferences>({ theme: 'system', setTheme: () => {}, animatedBackground: true, setAnimatedBackground: () => {} });
const key = 'freebay.preferences';
export function PreferencesProvider({ children }: React.PropsWithChildren) {
  const [theme, setTheme] = useState<Theme>('system'); const [animatedBackground, setAnimatedBackground] = useState(true);
  useEffect(() => { try { const saved: unknown = JSON.parse(localStorage.getItem(key) ?? '{}'); if (!saved || typeof saved !== 'object') return; if ('theme' in saved && (saved.theme === 'light' || saved.theme === 'dark' || saved.theme === 'system')) setTheme(saved.theme); if ('animatedBackground' in saved && typeof saved.animatedBackground === 'boolean') setAnimatedBackground(saved.animatedBackground); } catch { /* malformed preference is ignored */ } }, []);
  useEffect(() => { const root = document.documentElement; const apply = () => { root.dataset.theme = theme === 'system' ? (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light') : theme; }; apply(); if (theme !== 'system') return; const media = matchMedia('(prefers-color-scheme: dark)'); media.addEventListener('change', apply); return () => media.removeEventListener('change', apply); }, [theme]);
  useEffect(() => { document.documentElement.dataset.aurora = animatedBackground ? 'on' : 'off'; try { localStorage.setItem(key, JSON.stringify({ theme, animatedBackground })); } catch { /* storage can be disabled */ } }, [theme, animatedBackground]);
  return <Context.Provider value={{ theme, setTheme, animatedBackground, setAnimatedBackground }}>{children}</Context.Provider>;
}
export function usePreferences() { return useContext(Context); }
