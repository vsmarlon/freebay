import { useEffect, useRef, useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { api } from '../../core/api';
import { accessTokenForSocket } from '../../core/api';
import { io } from 'socket.io-client';
import { notificationDestination } from './notification-destination';
import { Frame, Panel, useAccountText } from './account';
import { useSession } from '../../core/session';
type Notice = { id: string; title?: string; body?: string; content?: string; read: boolean; createdAt: string; data?: unknown; type?: string };
type Page = { items?: Notice[]; data?: Notice[]; nextCursor?: string | null; hasMore?: boolean };
export class NotificationRequestScope {
  readonly controller = new AbortController();
  private active = true;

  constructor(private readonly isAccountCurrent: () => boolean) {}

  isCurrent() { return this.active && !this.controller.signal.aborted && this.isAccountCurrent(); }

  cancel() { this.active = false; this.controller.abort(); }

  async apply<T>(request: Promise<T>, onSuccess: (value: T) => void, onError: () => void) {
    try {
      const value = await request;
      if (this.isCurrent()) onSuccess(value);
    } catch {
      if (this.isCurrent()) onError();
    }
  }
}

export default function NotificationsPage() {
  const { t, path } = useAccountText(); const navigate = useNavigate(); const { user } = useSession(); const userId = user?.id; const currentUserId = useRef(userId); currentUserId.current = userId; const requestScope = useRef<NotificationRequestScope | null>(null); const [items, setItems] = useState<Notice[]>([]); const [cursor, setCursor] = useState<string | null>(null); const [more, setMore] = useState(false); const [error, setError] = useState(false); const [unreadCount, setUnreadCount] = useState<number | null>(null); const [countError, setCountError] = useState(false); const [busy, setBusy] = useState<string | null>(null);
  function refreshUnread(scope = requestScope.current) {
    if (!scope?.isCurrent()) return;
    setCountError(false);
    void scope.apply(api.get<{ count: number }>('/notifications/unread-count', { signal: scope.controller.signal }), (result: { count: number }) => {
      if (typeof result.count !== 'number' || !Number.isInteger(result.count) || result.count < 0) { setCountError(true); return; }
      setUnreadCount(result.count);
    }, () => setCountError(true));
  }
  function load(next = false, scope = requestScope.current) {
    if (!scope?.isCurrent()) return;
    setError(false);
    const query = new URLSearchParams({ limit: '20', ...(next && cursor ? { cursor } : {}) });
    void scope.apply(api.get<Page | Notice[]>(`/notifications?${query}`, { signal: scope.controller.signal }), (result: Page | Notice[]) => {
      const rows = Array.isArray(result) ? result : result.items ?? result.data ?? [];
      setItems((old) => next ? [...old, ...rows] : rows);
      if (!Array.isArray(result)) { setCursor(result.nextCursor ?? null); setMore(result.hasMore ?? Boolean(result.nextCursor)); }
    }, () => setError(true));
  }
  useEffect(() => {
    const scope: NotificationRequestScope = new NotificationRequestScope(() => currentUserId.current === userId && requestScope.current === scope);
    requestScope.current = scope;
    setItems([]); setCursor(null); setMore(false); setError(false); setUnreadCount(null); setCountError(false); setBusy(null);
    load(false, scope); refreshUnread(scope);
    return () => { scope.cancel(); if (requestScope.current === scope) requestScope.current = null; };
  }, [userId]);
  useEffect(() => { let active = true; let socket: ReturnType<typeof io> | undefined; if (userId) { socket = io(`${location.origin}/notifications`, { auth: (callback) => { void accessTokenForSocket().then((token) => callback({ token })).catch(() => callback({ token: '' })); }, transports: ['websocket'] }); const refresh = () => { if (active) { load(); refreshUnread(); } }; socket.on('notification', refresh); socket.on('connect', refresh); } return () => { active = false; socket?.disconnect(); }; }, [userId]);
  async function readAll() { setBusy('all'); try { await api.post('/notifications/read-all'); setItems((all) => all.map((item) => ({ ...item, read: true }))); await refreshUnread(); } catch { setError(true); } finally { setBusy(null); } }
  async function open(item: Notice) { if (!item.read) { setBusy(item.id); try { await api.patch(`/notifications/${encodeURIComponent(item.id)}/read`); setItems((all) => all.map((n) => n.id === item.id ? { ...n, read: true } : n)); await refreshUnread(); } catch { setError(true); return false; } finally { setBusy(null); } } return true; }
  // Destinations are intentionally mapped only from validated identifiers, never notification-provided URLs.
  return <Frame title={t('notifications')}><Panel><div className="mb-4 flex flex-wrap items-center justify-between gap-3"><p aria-live="polite">{t('unreadCount', { count: unreadCount ?? '—' })}</p><button disabled={busy !== null} className="min-h-11 bg-surface-high px-4" onClick={() => void readAll()}>{busy === 'all' ? t('loading') : t('unread')}</button></div>{countError ? <p role="alert" className="text-danger">{t('unreadCountError')} <button className="underline" onClick={() => void refreshUnread()}>{t('retry')}</button></p> : null}{error ? <p role="alert" className="text-danger">{t('error')} <button onClick={() => void load()}>{t('retry')}</button></p> : null}{!items.length && !error ? <p>{t('emptyNotifications')}</p> : null}<div className="grid gap-2">{items.map((item) => { const route = notificationDestination({ ...(item.data && typeof item.data === 'object' ? item.data : {}), type: item.type }); return <article key={item.id} className={`bg-surface-mid p-4 ${item.read ? '' : 'border-l-4 border-brand'}`}><h2 className="font-semibold">{item.title ?? item.content ?? t('notifications')}</h2>{item.body ? <p>{item.body}</p> : null}<time className="text-sm text-secondary" dateTime={item.createdAt}>{new Date(item.createdAt).toLocaleString()}</time>{route ? <Link onClick={(event) => { event.preventDefault(); void open(item).then((ok) => { if (ok) navigate(path(route)); }); }} aria-disabled={busy === item.id} className="ml-3 underline" to={path(route)}>{t('open')}</Link> : <button disabled={busy === item.id} className="ml-3 underline" onClick={() => void open(item)}>{item.read ? t('read') : t('unread')}</button>}</article>; })}</div>{more ? <button className="mt-4 min-h-11 bg-surface-high px-4" onClick={() => void load(true)}>{t('loadMore')}</button> : null}</Panel></Frame>;
}
