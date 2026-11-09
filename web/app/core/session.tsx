import {
  createContext,
  useCallback,
  useContext,
  useRef,
  useState,
  useSyncExternalStore,
} from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router';
import { ApiError, accessTokenForSocket, api, clearAccessToken, refreshAccessToken } from './api';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useI18n } from './locale';
import { appPath, paths, safeLocalizedReturnTo } from './routes';

export type SessionUser = {
  id: string;
  displayName: string;
  username: string | null;
  avatarUrl: string | null;
  role: 'USER' | 'ADMIN';
};
type SessionValue = {
  user: SessionUser | null;
  isPending: boolean;
  isSigningOut: boolean;
  signOutFailed: boolean;
  error: Error | null;
  reload: () => Promise<void>;
  signOut: () => Promise<void>;
};
const Context = createContext<SessionValue>({
  user: null,
  isPending: true,
  isSigningOut: false,
  signOutFailed: false,
  error: null,
  reload: async () => {},
  signOut: async () => {},
});
function parseUser(value: unknown): SessionUser {
  if (
    !value ||
    typeof value !== 'object' ||
    !('id' in value) ||
    typeof value.id !== 'string' ||
    !('displayName' in value) ||
    typeof value.displayName !== 'string'
  )
    throw new Error('Invalid session user response');
  return {
    id: value.id,
    displayName: value.displayName,
    username: 'username' in value && typeof value.username === 'string' ? value.username : null,
    avatarUrl: 'avatarUrl' in value && typeof value.avatarUrl === 'string' ? value.avatarUrl : null,
    role: 'role' in value && value.role === 'ADMIN' ? 'ADMIN' : 'USER',
  };
}

const welcomesSeenInMemory = new Set<string>();
export function hasSeenWelcome(userId: string) {
  try {
    return (
      localStorage.getItem(`freebay.welcome.seen.${encodeURIComponent(userId)}`) === 'true' ||
      welcomesSeenInMemory.has(userId)
    );
  } catch {
    return welcomesSeenInMemory.has(userId);
  }
}
export function completeWelcome(userId: string) {
  welcomesSeenInMemory.add(userId);
  try {
    localStorage.setItem(`freebay.welcome.seen.${encodeURIComponent(userId)}`, 'true');
  } catch {
    /* this tab remembers the choice */
  }
}

type LogoutStore = {
  version: number;
  at: number;
  listeners: Set<() => void>;
  channel: BroadcastChannel | null;
};
const logoutStore: LogoutStore = { version: 0, at: 0, listeners: new Set(), channel: null };
let storageBound = false;
function publishLogout() {
  logoutStore.version += 1;
  logoutStore.at = Date.now();
  for (const listener of logoutStore.listeners) listener();
}
function subscribeLogout(listener: () => void) {
  logoutStore.listeners.add(listener);
  if (typeof BroadcastChannel !== 'undefined' && !logoutStore.channel) {
    const channel = new BroadcastChannel('freebay.session');
    channel.onmessage = (event: MessageEvent<unknown>) => {
      if (
        event.data &&
        typeof event.data === 'object' &&
        'type' in event.data &&
        (event.data as { type?: unknown }).type === 'logout'
      )
        publishLogout();
    };
    logoutStore.channel = channel;
  }
  if (!storageBound && typeof window !== 'undefined') {
    storageBound = true;
    window.addEventListener('storage', (event: StorageEvent) => {
      if (event.key === 'freebay.session.logout' && event.newValue) publishLogout();
    });
  }
  return () => {
    logoutStore.listeners.delete(listener);
  };
}

function SessionStateProvider({ children }: React.PropsWithChildren) {
  const [isSigningOut, setSigningOut] = useState(false);
  const [signOutFailed, setSignOutFailed] = useState(false);
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const { locale } = useI18n();
  const reloadId = useRef(0);
  const logoutFlight = useRef(false);
  const loggedOutVersion = useSyncExternalStore(
    subscribeLogout,
    () => logoutStore.version,
    () => 0,
  );
  const {
    data: rawUser,
    isPending: queryPending,
    error,
    refetch,
    dataUpdatedAt,
  } = useQuery<SessionUser | null>({
    queryKey: ['session', 'user'],
    queryFn: async ({ signal }) => {
      clearAccessToken();
      try {
        const result = await api.get<unknown>('/users/me', { signal });
        return parseUser(result);
      } catch (cause) {
        if (cause instanceof ApiError && cause.status === 401) return null;
        throw cause instanceof Error ? cause : new Error('Unable to load session');
      }
    },
    retry: false,
    refetchOnWindowFocus: false,
  });
  const signedOut = loggedOutVersion > 0 && dataUpdatedAt <= logoutStore.at;
  const user = signedOut ? null : (rawUser ?? null);
  const isPending = queryPending && !signedOut;

  const reload = useCallback(async () => {
    const id = ++reloadId.current;
    clearAccessToken();
    try {
      await queryClient.cancelQueries({ queryKey: ['session', 'user'] });
    } catch {
      /* ignore */
    }
    await queryClient.removeQueries({ queryKey: ['session', 'user'] });
    if (id !== reloadId.current) return;
    try {
      await refetch();
    } catch {
      /* error state reflects it */
    }
  }, [queryClient, refetch]);

  const signOut = useCallback(async () => {
    if (logoutFlight.current) return;
    logoutFlight.current = true;
    const operation = ++reloadId.current;
    setSigningOut(true);
    setSignOutFailed(false);
    clearAccessToken();
    try {
      await queryClient.cancelQueries();
      queryClient.clear();
      await api.post('/auth/web/session/logout', undefined, { auth: false });
    } catch (cause) {
      if (operation !== reloadId.current) {
        logoutFlight.current = false;
        return;
      }
      setSignOutFailed(true);
      setSigningOut(false);
      logoutFlight.current = false;
      throw cause;
    }
    if (operation !== reloadId.current) {
      logoutFlight.current = false;
      return;
    }
    publishLogout();
    setSigningOut(false);
    setSignOutFailed(false);
    logoutFlight.current = false;
    if (typeof BroadcastChannel !== 'undefined') {
      try {
        const channel = new BroadcastChannel('freebay.session');
        channel.postMessage({ type: 'logout', at: Date.now() });
        channel.close();
      } catch {
        /* best effort */
      }
    }
    try {
      localStorage.setItem('freebay.session.logout', String(Date.now()));
    } catch {
      /* cross-tab notification is best effort */
    }
    navigate(appPath(locale, paths.login), { replace: true });
  }, [locale, navigate, queryClient]);

  return (
    <Context.Provider
      value={{
        user: isSigningOut ? null : user,
        isPending,
        isSigningOut,
        signOutFailed,
        error: error instanceof Error ? error : error ? new Error(String(error)) : null,
        reload,
        signOut,
      }}
    >
      {children}
    </Context.Provider>
  );
}
export function SessionProvider({ children }: React.PropsWithChildren) {
  return <SessionStateProvider>{children}</SessionStateProvider>;
}
export function useSession() {
  return useContext(Context);
}
export const session = {
  current: async () => {
    try {
      return parseUser(await api.get<unknown>('/users/me'));
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) return null;
      throw error;
    }
  },
  refresh: async () => {
    await refreshAccessToken();
  },
  logout: async () => {
    await api.post('/auth/web/session/logout', undefined, { auth: false });
    clearAccessToken();
  },
  socketToken: () => accessTokenForSocket(),
};
export function RequireAuth({ children }: React.PropsWithChildren) {
  const { user, isPending, isSigningOut, error, reload } = useSession();
  const { locale } = useI18n();
  const location = useLocation();
  const requestedPath = safeLocalizedReturnTo(
    `${location.pathname}${location.search}${location.hash}`,
    locale,
  );
  const returnAfterWelcome = safeLocalizedReturnTo(
    new URLSearchParams(location.search).get('returnTo'),
    locale,
  );
  const isWelcome = location.pathname === appPath(locale, paths.welcome);
  const isCompleteProfile = location.pathname === appPath(locale, paths.completeProfile);
  if (isPending || isSigningOut)
    return <p role="status">{locale === 'en' ? 'Loading…' : 'Carregando…'}</p>;
  if (error)
    return (
      <section role="alert">
        <p>
          {locale === 'en'
            ? 'Unable to check your session.'
            : 'Não foi possível verificar sua sessão.'}
        </p>
        <button type="button" onClick={() => void reload().catch(() => {})}>
          {locale === 'en' ? 'Try again' : 'Tentar novamente'}
        </button>
      </section>
    );
  if (!user)
    return (
      <Navigate
        to={`${appPath(locale, paths.login)}?returnTo=${encodeURIComponent(requestedPath)}`}
        replace
      />
    );
  if (!user.username && !isCompleteProfile)
    return (
      <Navigate
        to={`${appPath(locale, paths.completeProfile)}?returnTo=${encodeURIComponent(requestedPath)}`}
        replace
      />
    );
  if (user.username && !isWelcome && !hasSeenWelcome(user.id))
    return (
      <Navigate
        to={`${appPath(locale, paths.welcome)}?returnTo=${encodeURIComponent(requestedPath)}`}
        replace
      />
    );
  if (user.username && isWelcome && hasSeenWelcome(user.id))
    return <Navigate to={returnAfterWelcome} replace />;
  return children;
}
