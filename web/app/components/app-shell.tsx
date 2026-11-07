import { useCallback, useState, useSyncExternalStore } from 'react';
import type { FocusEvent, KeyboardEvent, PointerEvent as ReactPointerEvent, ReactNode } from 'react';
import { Link, useLocation } from 'react-router';
import { useI18n } from '../core/locale';
import { paths, appPath } from '../core/routes';
import { useSession } from '../core/session';
import { Avatar, Button, Icon } from './index';
import { BrandMark } from './brand-mark';
import { ThemeControl } from './theme-control';

const SIDEBAR_MIN = 200;
const SIDEBAR_MAX = 400;
const SIDEBAR_DEFAULT = 240;
const SIDEBAR_COLLAPSED = 68;
const storageKey = 'freebay.sidebar';
type SidebarPrefs = { width: number; collapsed: boolean };
const fallbackSidebar: SidebarPrefs = { width: SIDEBAR_DEFAULT, collapsed: false };

// null = nothing stored yet (first load); the caller applies the viewport-based default.
function readSidebar(): SidebarPrefs | null {
  try {
    const raw = localStorage.getItem(storageKey);
    if (!raw) return null;
    const saved: unknown = JSON.parse(raw);
    if (!saved || typeof saved !== 'object') return null;
    const width = 'width' in saved && typeof saved.width === 'number' && Number.isFinite(saved.width) ? Math.min(SIDEBAR_MAX, Math.max(SIDEBAR_MIN, saved.width)) : SIDEBAR_DEFAULT;
    const collapsed = 'collapsed' in saved && saved.collapsed === true;
    return { width, collapsed };
  } catch {
    return fallbackSidebar;
  }
}

export function AppShell({ children }: React.PropsWithChildren) {
  const { locale, t } = useI18n();
  const location = useLocation();
  const { user, isSigningOut, signOutFailed, signOut } = useSession();
  const [open, setOpen] = useState<'nav' | 'account' | null>(null);
  // SSR/first paint = expanded default; stored prefs apply after hydration (see useSyncExternalStore), matching the root theme pattern.
  const hydrated = useSyncExternalStore(() => () => {}, () => true, () => false);
  const [width, setWidth] = useState(SIDEBAR_DEFAULT);
  const [collapsed, setCollapsed] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [restored, setRestored] = useState(false);
  if (hydrated && !restored) {
    // one-shot adopt of persisted prefs after hydration; no effect needed. Nothing stored → first-load default: collapsed on 760–1100px, expanded above.
    const saved = readSidebar();
    const narrowDefault = typeof window !== 'undefined' && window.innerWidth <= 1100;
    setWidth(saved?.width ?? SIDEBAR_DEFAULT);
    setCollapsed(saved?.collapsed ?? narrowDefault);
    setRestored(true);
  }
  // Dropdown dismissal without effects: blur leaves only when focus jumps outside the wrapper, Escape closes on bubble.
  const dismiss = (event: FocusEvent<HTMLDivElement>) => { if (!(event.relatedTarget instanceof Node) || !event.currentTarget.contains(event.relatedTarget)) setOpen(null); };
  const escape = (event: KeyboardEvent<HTMLDivElement>) => { if (event.key === 'Escape') setOpen(null); };

  const primaryTabs = [
    { key: 'home', icon: 'home', title: t('nav.home'), href: paths.feed },
    { key: 'explore', icon: 'explore', title: t('nav.explore'), href: paths.explore },
    { key: 'sell', icon: 'sell', title: t('nav.sell'), href: paths.sell },
    { key: 'messages', icon: 'messages', title: t('nav.messages'), href: paths.messages },
    { key: 'profile', icon: 'profile', title: t('nav.profile'), href: paths.profile },
  ] as const;
  const sidebarTabs = [...primaryTabs, { key: 'settings', icon: 'gear', title: t('menu.settings'), href: paths.settings } as const];
  const to = (href: string) => appPath(locale, href);
  const isActive = (href: string) => location.pathname === (href ? to(href) : `/${locale}`);
  const drop = (entries: ReactNode, end = false) => <div className={`app-drop${end ? ' app-drop-end' : ''}`} role="menu" onBlur={dismiss}>{entries}</div>;
  const persistSidebar = (next: SidebarPrefs) => {
    try { localStorage.setItem(storageKey, JSON.stringify(next)); } catch { /* storage can be disabled */ }
  };
  const clampWidth = (value: number) => Math.min(SIDEBAR_MAX, Math.max(SIDEBAR_MIN, Math.round(value)));
  const commitWidth = useCallback((value: number) => {
    const nextWidth = clampWidth(value);
    setWidth(nextWidth);
    persistSidebar({ width: nextWidth, collapsed });
  }, [collapsed]);
  const toggleCollapsed = useCallback(() => {
    setCollapsed((current) => {
      const next = !current;
      persistSidebar({ width, collapsed: next });
      return next;
    });
  }, [width]);

  // Drag-resizable expanded sidebar: drag the right edge or use arrows on it; collapsed rails do nothing until expanded again.
  const expandSidebar = useCallback(() => {
    setCollapsed(false);
    persistSidebar({ width, collapsed: false });
  }, [width]);
  const onDragStart = (event: ReactPointerEvent<HTMLDivElement>) => {
    if (collapsed) { expandSidebar(); return; }
    event.preventDefault();
    const startX = event.clientX;
    const startWidth = width;
    const target = event.currentTarget;
    target.setPointerCapture(event.pointerId);
    setDragging(true);
    const onMove = (moveEvent: PointerEvent) => {
      const nextWidth = clampWidth(startWidth + moveEvent.clientX - startX);
      setWidth(nextWidth);
    };
    const onEnd = (endEvent: PointerEvent) => {
      target.removeEventListener('pointermove', onMove);
      target.removeEventListener('pointerup', onEnd);
      target.removeEventListener('pointercancel', onEnd);
      const finalWidth = clampWidth(startWidth + endEvent.clientX - startX);
      setWidth(finalWidth);
      persistSidebar({ width: finalWidth, collapsed: false });
      setDragging(false);
    };
    target.addEventListener('pointermove', onMove);
    target.addEventListener('pointerup', onEnd);
    target.addEventListener('pointercancel', onEnd);
  };
  const onHandleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key !== 'ArrowLeft' && event.key !== 'ArrowRight') return;
    event.preventDefault();
    const delta = event.key === 'ArrowLeft' ? -16 : 16;
    commitWidth(width + delta);
  };

  const effectiveWidth = collapsed ? SIDEBAR_COLLAPSED : width;
  const sidebarVar = { '--sidebar-w': `${effectiveWidth}px` } as React.CSSProperties;

  return <div className="app-shell" data-collapsed={collapsed ? 'true' : 'false'} data-dragging={dragging ? 'true' : undefined} style={sidebarVar}>
    <aside className="app-sidebar">
      <div className="app-sidebar-top">
        <Link className="brand" to={`/${locale}`}><BrandMark className="brand-mark" /><span className="app-brand-label">freebay</span></Link>
        <button className="app-collapse-toggle" type="button" onClick={toggleCollapsed} aria-expanded={!collapsed} aria-label={collapsed ? t('nav.expandSidebar') : t('nav.collapseSidebar')} title={collapsed ? t('nav.expandSidebar') : t('nav.collapseSidebar')}><Icon name="sidebarToggle" size={18} /></button>
      </div>
      <nav aria-label={locale === 'en' ? 'Primary navigation' : 'Navegação principal'}>
        {sidebarTabs.map(({ key, icon, title, href }) => <Link key={key} to={to(href)} aria-current={isActive(href) ? 'page' : undefined} aria-label={title} title={collapsed ? title : undefined}><Icon name={icon} size={18} /><span className="app-nav-label">{title}</span></Link>)}
      </nav>
      <div className="app-resize-handle" role="separator" aria-orientation="vertical" aria-label={t('nav.resizeSidebar')} aria-valuemin={SIDEBAR_MIN} aria-valuemax={SIDEBAR_MAX} aria-valuenow={Math.round(width)} aria-hidden={collapsed ? true : undefined} tabIndex={collapsed ? -1 : 0} onPointerDown={onDragStart} onKeyDown={onHandleKeyDown} />
    </aside>
    <header className="app-topbar">
      <div className="app-wrap app-nav-wrap" onBlur={dismiss} onKeyDown={escape}>
        <button className="app-action" type="button" onClick={() => setOpen(open === 'nav' ? null : 'nav')} aria-expanded={open === 'nav'} aria-haspopup="menu" aria-label={t('nav.menu')}><Icon name={open === 'nav' ? 'close' : 'menu'} size={20} /></button>
        {open === 'nav' ? drop(sidebarTabs.map(({ key, icon, title, href }) => <Link key={key} role="menuitem" className={isActive(href) ? 'is-active' : undefined} to={to(href)} onClick={() => setOpen(null)}><Icon name={icon} size={18} />{title}</Link>)) : null}
      </div>
      <Link className="app-topbar-brand brand" to={`/${locale}`}><BrandMark className="brand-mark" /></Link>
      <form className="app-search" action={to(paths.search)}>
        <label className="visually-hidden" htmlFor="app-search">{t('common.search')}</label>
        <input id="app-search" name="q" type="search" placeholder={t('common.search')} />
        <button type="submit" aria-label={t('common.search')}>⌕</button>
      </form>
      <div className="app-topbar-actions">
        <Link className="app-action" to={to(paths.notifications)} aria-label={t('nav.notifications')}><Icon name="bell" size={20} /></Link>
        <ThemeControl />
        <div className="app-wrap" onBlur={dismiss} onKeyDown={escape}>
          <button className="app-account" type="button" onClick={() => setOpen(open === 'account' ? null : 'account')} aria-expanded={open === 'account'} aria-haspopup="menu" aria-label={user?.displayName ?? t('common.account')}>
            <Avatar src={user?.avatarUrl} name={user?.displayName ?? t('common.account')} size={38} />
          </button>
          {open === 'account' ? drop(<>
            <Link role="menuitem" to={to(paths.profile)} onClick={() => setOpen(null)}><Icon name="profile" size={16} />{t('menu.profileView')}</Link>
            <Link role="menuitem" to={to(paths.editProfile)} onClick={() => setOpen(null)}><Icon name="pencil" size={16} />{t('menu.editProfile')}</Link>
            <Link role="menuitem" to={to(paths.cart)} onClick={() => setOpen(null)}><Icon name="cart" size={16} />{t('menu.cart')}</Link>
            <Link role="menuitem" to={to(paths.liked)} onClick={() => setOpen(null)}><Icon name="heart" size={16} />{t('menu.likes')}</Link>
            <Link role="menuitem" to={to(paths.settings)} onClick={() => setOpen(null)}><Icon name="gear" size={16} />{t('menu.settings')}</Link>
            <hr />
            <button type="button" role="menuitem" disabled={isSigningOut} onClick={() => { setOpen(null); void signOut().catch(() => {}); }}><Icon name="signOut" size={16} />{t('menu.signOut')}</button>
          </>, true) : null}
        </div>
        <Link className="app-locale" to={appPath(locale === 'en' ? 'pt-BR' : 'en', paths.feed)} lang={locale === 'en' ? 'pt-BR' : 'en'}>{locale === 'en' ? 'PT' : 'EN'}</Link>
      </div>
    </header>
    <main id="main-content" className="app-content">
      {signOutFailed ? <section className="error-state" role="alert"><p>{t('session.logoutFailed')}</p><Button variant="secondary" onClick={() => void signOut().catch(() => {})}>{t('session.logoutRetry')}</Button></section> : null}
      <div key={user?.id ?? 'signed-out'}>{children}</div>
    </main>
    <nav className="mobile-tabs" aria-label={locale === 'en' ? 'Primary navigation' : 'Navegação principal'}>
      {primaryTabs.map(({ key, icon, title, href }) => <Link key={key} to={to(href)} aria-current={isActive(href) ? 'page' : undefined}><Icon name={icon} size={16} />{title}</Link>)}
    </nav>
  </div>;
}
