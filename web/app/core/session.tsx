import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { useLocation, useNavigate } from 'react-router';
import { ApiError, accessTokenForSocket, api, clearAccessToken, refreshAccessToken } from './api';
import { useQueryClient } from '@tanstack/react-query';
import { useI18n } from './locale';
import { appPath, paths, safeLocalizedReturnTo } from './routes';

export type SessionUser = { id: string; displayName: string; username: string | null; avatarUrl: string | null };
type SessionValue = { user: SessionUser | null; isPending: boolean; isSigningOut: boolean; signOutFailed: boolean; error: Error | null; reload: () => Promise<void>; signOut: () => Promise<void> };
const Context = createContext<SessionValue>({ user: null, isPending: true, isSigningOut: false, signOutFailed: false, error: null, reload: async () => {}, signOut: async () => {} });
function parseUser(value: unknown): SessionUser { if (!value || typeof value !== 'object' || !('id' in value) || typeof value.id !== 'string' || !('displayName' in value) || typeof value.displayName !== 'string') throw new Error('Invalid session user response'); return { id: value.id, displayName: value.displayName, username: 'username' in value && typeof value.username === 'string' ? value.username : null, avatarUrl: 'avatarUrl' in value && typeof value.avatarUrl === 'string' ? value.avatarUrl : null }; }

let onboardingSeenInMemory = false;
const welcomesSeenInMemory = new Set<string>();
export function hasCompletedOnboarding() { try { return localStorage.getItem('freebay.onboarding.seen') === 'true' || onboardingSeenInMemory; } catch { return onboardingSeenInMemory; } }
export function completeOnboarding() { onboardingSeenInMemory = true; try { localStorage.setItem('freebay.onboarding.seen', 'true'); } catch { /* this tab remembers the choice */ } }
export function hasSeenWelcome(userId: string) { try { return localStorage.getItem(`freebay.welcome.seen.${encodeURIComponent(userId)}`) === 'true' || welcomesSeenInMemory.has(userId); } catch { return welcomesSeenInMemory.has(userId); } }
export function completeWelcome(userId: string) { welcomesSeenInMemory.add(userId); try { localStorage.setItem(`freebay.welcome.seen.${encodeURIComponent(userId)}`, 'true'); } catch { /* this tab remembers the choice */ } }

function SessionStateProvider({ children }: React.PropsWithChildren) {
  const [user, setUser] = useState<SessionUser | null>(null); const [isPending, setPending] = useState(true); const [isSigningOut, setSigningOut] = useState(false); const [signOutFailed, setSignOutFailed] = useState(false); const [error, setError] = useState<Error | null>(null); const queryClient = useQueryClient(); const navigate = useNavigate(); const { locale } = useI18n(); const reloadId = useRef(0); const logoutFlight = useRef(false);
  const reload = useCallback(async () => { const id = ++reloadId.current; clearAccessToken(); setUser(null); setPending(true); setError(null); try { await queryClient.cancelQueries(); queryClient.removeQueries({ queryKey: ['user'] }); const result = await api.get<unknown>('/users/me'); if (id === reloadId.current) { setUser(parseUser(result)); setSignOutFailed(false); } } catch (cause) { if (id !== reloadId.current) return; if (cause instanceof ApiError && cause.status === 401) setUser(null); else { const failure = cause instanceof Error ? cause : new Error('Unable to load session'); setError(failure); throw failure; } } finally { if (id === reloadId.current) setPending(false); } }, [queryClient]);
  const signOut = useCallback(async () => {
    if (logoutFlight.current) return;
    logoutFlight.current = true;
    const operation = ++reloadId.current; setPending(false); setSigningOut(true); setSignOutFailed(false); clearAccessToken();
    try {
      await queryClient.cancelQueries();
      queryClient.clear();
      await api.post('/auth/web/session/logout', undefined, { auth: false });
    } catch (cause) {
      if (operation !== reloadId.current) { logoutFlight.current = false; return; }
      setSignOutFailed(true); setSigningOut(false); logoutFlight.current = false;
      throw cause;
    }
    if (operation !== reloadId.current) { logoutFlight.current = false; return; }
    setUser(null); setSigningOut(false); setSignOutFailed(false); logoutFlight.current = false;
    const at = Date.now();
    if (typeof BroadcastChannel !== 'undefined') { const channel = new BroadcastChannel('freebay.session'); channel.postMessage({ type: 'logout', at }); channel.close(); }
    try { localStorage.setItem('freebay.session.logout', String(at)); } catch { /* cross-tab notification is best effort */ }
    navigate(appPath(locale, paths.login), { replace: true });
  }, [locale, navigate, queryClient]);
  useEffect(() => { void reload().catch(() => {}); }, [reload]);
  const receiveLogout = useCallback(() => { ++reloadId.current; clearAccessToken(); setUser(null); setPending(false); setSigningOut(false); setSignOutFailed(false); queryClient.clear(); }, [queryClient]);
  useEffect(() => { if (typeof BroadcastChannel === 'undefined') return; const channel = new BroadcastChannel('freebay.session'); channel.onmessage = (event: MessageEvent<unknown>) => { if (event.data && typeof event.data === 'object' && 'type' in event.data && event.data.type === 'logout') receiveLogout(); }; return () => channel.close(); }, [receiveLogout]);
  useEffect(() => { const onStorage = (event: StorageEvent) => { if (event.key === 'freebay.session.logout' && event.newValue) receiveLogout(); }; window.addEventListener('storage', onStorage); return () => window.removeEventListener('storage', onStorage); }, [receiveLogout]);
  return <Context.Provider value={{ user: isSigningOut ? null : user, isPending, isSigningOut, signOutFailed, error, reload, signOut }}>{children}</Context.Provider>;
}
export function SessionProvider({ children }: React.PropsWithChildren) { return <SessionStateProvider>{children}</SessionStateProvider>; }
export function useSession() { return useContext(Context); }
export const session = { current: async () => { try { return parseUser(await api.get<unknown>('/users/me')); } catch (error) { if (error instanceof ApiError && error.status === 401) return null; throw error; } }, refresh: async () => { await refreshAccessToken(); }, logout: async () => { await api.post('/auth/web/session/logout', undefined, { auth: false }); clearAccessToken(); }, socketToken: () => accessTokenForSocket() };
export function RequireAuth({ children }: React.PropsWithChildren) {
  const { user, isPending, isSigningOut, error, reload } = useSession(); const { locale } = useI18n(); const location = useLocation(); const navigate = useNavigate();
  const requestedPath = safeLocalizedReturnTo(`${location.pathname}${location.search}${location.hash}`, locale);
  const returnAfterWelcome = safeLocalizedReturnTo(new URLSearchParams(location.search).get('returnTo'), locale);
  const isWelcome = location.pathname === appPath(locale, paths.welcome);
  const isCompleteProfile = location.pathname === appPath(locale, paths.completeProfile);
  useEffect(() => {
    if (isPending || isSigningOut || error) return;
    if (!user) {
      const destination = hasCompletedOnboarding() ? paths.login : paths.onboarding;
      navigate(`${appPath(locale, destination)}?returnTo=${encodeURIComponent(requestedPath)}`, { replace: true });
    } else if (!user.username && !isCompleteProfile) {
      navigate(`${appPath(locale, paths.completeProfile)}?returnTo=${encodeURIComponent(requestedPath)}`, { replace: true });
    } else if (user.username && !isWelcome && !hasSeenWelcome(user.id)) {
      navigate(`${appPath(locale, paths.welcome)}?returnTo=${encodeURIComponent(requestedPath)}`, { replace: true });
    } else if (user.username && isWelcome && hasSeenWelcome(user.id)) {
      navigate(returnAfterWelcome, { replace: true });
    }
  }, [error, isCompleteProfile, isPending, isSigningOut, isWelcome, locale, navigate, requestedPath, returnAfterWelcome, user]);
  if (isPending || isSigningOut) return <p role="status">{locale === 'en' ? 'Loading…' : 'Carregando…'}</p>;
  if (error) return <section role="alert"><p>{locale === 'en' ? 'Unable to check your session.' : 'Não foi possível verificar sua sessão.'}</p><button type="button" onClick={() => void reload().catch(() => {})}>{locale === 'en' ? 'Try again' : 'Tentar novamente'}</button></section>;
  if (!user || (!user.username && !isCompleteProfile)) return null;
  return user.username && !isWelcome && !hasSeenWelcome(user.id) ? null : children;
}
