import { useCallback, useState, useSyncExternalStore } from 'react';
import type {
  FocusEvent,
  KeyboardEvent,
  PointerEvent as ReactPointerEvent,
  ReactNode,
} from 'react';
import { Link, useLocation, useNavigate } from 'react-router';
import { useI18n, type Locale } from '../core/locale';
import { paths, appPath } from '../core/routes';
import { useSession } from '../core/session';
import { Avatar, Button, Icon, SegmentedControl } from './index';
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
    const width =
      'width' in saved && typeof saved.width === 'number' && Number.isFinite(saved.width)
        ? Math.min(SIDEBAR_MAX, Math.max(SIDEBAR_MIN, saved.width))
        : SIDEBAR_DEFAULT;
    const collapsed = 'collapsed' in saved && saved.collapsed === true;
    return { width, collapsed };
  } catch {
    return fallbackSidebar;
  }
}

export function AppShell({ children }: React.PropsWithChildren) {
  const { locale, t } = useI18n();
  const location = useLocation();
  const navigate = useNavigate();
  const { user, isSigningOut, signOutFailed, signOut } = useSession();
  const [open, setOpen] = useState<'nav' | 'account' | null>(null);
  const [searchScope, setSearchScope] = useState<'products' | 'people'>('products');
  // SSR/first paint = expanded default; stored prefs apply after hydration (see useSyncExternalStore), matching the root theme pattern.
  const hydrated = useSyncExternalStore(
    () => () => {},
    () => true,
    () => false,
  );
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
  const dismiss = (event: FocusEvent<HTMLDivElement>) => {
    if (
      !(event.relatedTarget instanceof Node) ||
      !event.currentTarget.contains(event.relatedTarget)
    )
      setOpen(null);
  };
  const escape = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === 'Escape') setOpen(null);
  };

  const primaryTabs = [
    { key: 'home', icon: 'home', title: t('nav.home'), href: paths.feed },
    { key: 'explore', icon: 'explore', title: t('nav.explore'), href: paths.explore },
    { key: 'sell', icon: 'sell', title: t('nav.sell'), href: paths.sell },
    { key: 'messages', icon: 'messages', title: t('nav.messages'), href: paths.messages },
    { key: 'profile', icon: 'profile', title: t('nav.profile'), href: paths.profile },
  ] as const;
  const sidebarTabs = [
    ...primaryTabs,
    { key: 'wallet', icon: 'wallet', title: t('nav.wallet'), href: paths.wallet },
    { key: 'settings', icon: 'gear', title: t('menu.settings'), href: paths.settings },
  ] as const;
  const to = (href: string) => appPath(locale, href);
  // ponytail: swap only the locale segment so switching language keeps the current route.
  const localeTarget = (next: 'en' | 'pt-BR') =>
    `/${next}${location.pathname.replace(/^\/(en|pt-BR)(?=\/|$)/, '')}${location.search}`;
  const isActive = (href: string) => location.pathname === (href ? to(href) : `/${locale}`);
  const drop = (entries: ReactNode, end = false) => (
    <div
      className={`absolute top-[calc(100%+6px)] z-6 grid min-w-[230px] gap-0.5 border-[1.5px] border-ink bg-surface p-2 shadow-[4px_4px_var(--edge)] max-[760px]:inset-x-[10px]  max-[760px]:min-w-0 ${end ? 'left-auto right-0 ' : 'left-0'}`}
      role="menu"
      onBlur={dismiss}
    >
      {entries}
    </div>
  );
  const persistSidebar = (next: SidebarPrefs) => {
    try {
      localStorage.setItem(storageKey, JSON.stringify(next));
    } catch {
      /* storage can be disabled */
    }
  };
  const clampWidth = (value: number) =>
    Math.min(SIDEBAR_MAX, Math.max(SIDEBAR_MIN, Math.round(value)));
  const commitWidth = useCallback(
    (value: number) => {
      const nextWidth = clampWidth(value);
      setWidth(nextWidth);
      persistSidebar({ width: nextWidth, collapsed });
    },
    [collapsed],
  );
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
    if (collapsed) {
      expandSidebar();
      return;
    }
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

  // Mobile chrome hides on scroll down and returns on scroll up, mirroring the
  // app's HideOnScrollController (12px accumulated delta, always visible at top).
  // Callback ref keeps the listener tied to the header node; no effect needed.
  const attachScrollChrome = useCallback((node: HTMLElement | null) => {
    if (!node) return;
    const mobile = window.matchMedia('(max-width: 639px)');
    let lastY = window.scrollY;
    let accumulated = 0;
    let hidden = false;
    const reveal = () => {
      accumulated = 0;
      if (!hidden) return;
      hidden = false;
      node.removeAttribute('data-chrome-hidden');
      node.removeAttribute('aria-hidden');
      node.inert = false;
    };
    const hide = () => {
      accumulated = 0;
      if (hidden) return;
      hidden = true;
      node.setAttribute('data-chrome-hidden', 'true');
      node.setAttribute('aria-hidden', 'true');
      node.inert = true;
    };
    const onScroll = () => {
      const y = window.scrollY;
      const delta = y - lastY;
      lastY = y;
      if (!mobile.matches || y <= 0) return reveal();
      if (delta === 0) return;
      const sameDirection = (delta > 0 && accumulated >= 0) || (delta < 0 && accumulated <= 0);
      accumulated = sameDirection ? accumulated + delta : delta;
      if (accumulated > 12) hide();
      else if (accumulated < -12) reveal();
    };
    const onViewport = () => {
      if (!mobile.matches) reveal();
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    mobile.addEventListener('change', onViewport);
    return () => {
      window.removeEventListener('scroll', onScroll);
      mobile.removeEventListener('change', onViewport);
    };
  }, []);

  const effectiveWidth = collapsed ? SIDEBAR_COLLAPSED : width;
  const chatThread = location.pathname
    .split('/')
    .filter(Boolean)
    .some((segment, index, segments) => segment === 'messages' && segments.length - index === 2);
  const sidebarVar = { '--sidebar-w': `${effectiveWidth}px` } as React.CSSProperties;

  return (
    <div
      className="group min-h-svh [--sidebar-w:240px] data-[chat=true]:flex data-[chat=true]:h-svh data-[chat=true]:flex-col data-[dragging=true]:cursor-col-resize data-[dragging=true]:select-none"
      data-chat={chatThread ? 'true' : undefined}
      data-collapsed={collapsed ? 'true' : 'false'}
      data-dragging={dragging ? 'true' : undefined}
      style={sidebarVar}
    >
      <aside className="fixed inset-y-0 left-0 z-2 flex w-(--sidebar-w) flex-col gap-11 overflow-hidden border-r border-[#ff9dee] bg-(--chrome) p-8 px-[22px] transition-[width,padding] duration-180 ease-linear group-data-[collapsed=true]:gap-7 group-data-[collapsed=true]:px-2 max-[760px]:hidden group-data-[dragging=true]:transition-none">
        <div className="relative grid min-h-[38px] grid-cols-[minmax(0,1fr)_38px] items-center gap-2 whitespace-nowrap">
          <Link
            className="inline-flex min-w-0 items-center gap-[9px] overflow-hidden font-display text-[19px] font-bold tracking-[-1px]"
            to={`/${locale}`}
          >
            <BrandMark className="block size-7 shrink-0 text-[#660062]" />
            <span className="overflow-hidden text-ellipsis group-data-[collapsed=true]:hidden">
              freebay
            </span>
          </Link>
          <button
            className="grid size-[38px] flex-none place-items-center justify-self-end border-0 bg-transparent p-0 text-ink hover:bg-surface-mid group-data-[collapsed=true]:static group-data-[collapsed=true]:justify-self-center group-data-[collapsed=true]:[&_svg]:scale-x-[-1]"
            type="button"
            onClick={toggleCollapsed}
            aria-expanded={!collapsed}
            aria-label={collapsed ? t('nav.expandSidebar') : t('nav.collapseSidebar')}
            title={collapsed ? t('nav.expandSidebar') : t('nav.collapseSidebar')}
          >
            <Icon name="sidebarToggle" size={18} />
          </button>
        </div>
        <nav
          className="grid gap-1.5 justify-items-stretch group-data-[collapsed=true]:justify-items-center"
          aria-label={locale === 'en' ? 'Primary navigation' : 'Navegação principal'}
        >
          {sidebarTabs.map(({ key, icon, title, href }) => (
            <Link
              key={key}
              className={`flex min-h-[42px] items-center gap-3 p-2.5 font-display text-[13px] font-bold hover:bg-surface-mid group-data-[collapsed=true]:justify-center group-data-[collapsed=true]:gap-0 group-data-[collapsed=true]:px-1.5 group-data-[collapsed=true]:py-3 ${isActive(href) ? 'bg-surface-mid shadow-[2px_2px_var(--edge)]' : ''}`}
              to={to(href)}
              aria-current={isActive(href) ? 'page' : undefined}
              aria-label={title}
              title={collapsed ? title : undefined}
            >
              <Icon name={icon} size={18} />
              <span className="overflow-hidden whitespace-nowrap group-data-[collapsed=true]:hidden">
                {title}
              </span>
            </Link>
          ))}
        </nav>
        <div
          className="absolute top-0 right-[-5px] z-5 h-full w-[10px] touch-none cursor-col-resize after:absolute after:inset-y-0  after:left-1 after:w-0.5 after:bg-transparent after:transition-colors after:duration-180 hover:after:bg-ink focus-visible:after:bg-ink max-[760px]:hidden"
          role="separator"
          aria-orientation="vertical"
          aria-label={t('nav.resizeSidebar')}
          aria-valuemin={SIDEBAR_MIN}
          aria-valuemax={SIDEBAR_MAX}
          aria-valuenow={Math.round(width)}
          aria-hidden={collapsed ? true : undefined}
          tabIndex={collapsed ? -1 : 0}
          onPointerDown={onDragStart}
          onKeyDown={onHandleKeyDown}
        />
      </aside>
      <header
        ref={attachScrollChrome}
        className="sticky top-0 z-3 ml-(--sidebar-w) flex min-h-[72px] items-center gap-2.5 border-b border-[#ff9dee] bg-(--chrome) px-7 py-3 transition-[margin-left,transform] duration-180 ease-linear data-[chrome-hidden=true]:pointer-events-none data-[chrome-hidden=true]:-translate-y-full group-data-[dragging=true]:transition-none group-data-[chat=true]:flex-none max-[760px]:m-0 max-[760px]:min-h-[58px] max-[760px]:flex-wrap max-[760px]:gap-[7px] max-[760px]:px-[14px] max-[760px]:py-2.5"
      >
        <div className="relative hidden max-[760px]:block" onBlur={dismiss} onKeyDown={escape}>
          <button
            className="grid size-[38px] cursor-pointer place-items-center border border-ink bg-surface-mid text-ink max-[760px]:size-[34px] max-[760px]:bg-surface-mid"
            type="button"
            onClick={() => setOpen(open === 'nav' ? null : 'nav')}
            aria-expanded={open === 'nav'}
            aria-haspopup="menu"
            aria-label={t('nav.menu')}
          >
            <Icon name={open === 'nav' ? 'close' : 'menu'} size={20} />
          </button>
          {open === 'nav'
            ? drop(
                sidebarTabs.map(({ key, icon, title, href }) => (
                  <Link
                    key={key}
                    role="menuitem"
                    className={`flex w-full items-center gap-2.5 px-3 py-2.5 font-display text-[13px] font-semibold text-ink hover:bg-surface-mid ${isActive(href) ? 'bg-surface-mid shadow-[2px_2px_var(--edge)]' : ''}`}
                    to={to(href)}
                    onClick={() => setOpen(null)}
                  >
                    <Icon name={icon} size={18} />
                    {title}
                  </Link>
                )),
              )
            : null}
        </div>
        <Link className="hidden items-center max-[760px]:inline-flex" to={`/${locale}`}>
          <BrandMark className="block size-7 shrink-0 text-[#660062]" />
        </Link>
        <form
          className="flex min-w-[120px] max-w-[640px] flex-1 border-[1.5px] border-ink bg-surface max-[760px]:order-2 max-[760px]:basis-full max-[760px]:max-w-none"
          action={to(searchScope === 'people' ? paths.peopleSearch : paths.search)}
        >
          <label className="sr-only" htmlFor="app-search">
            {searchScope === 'people' ? t('common.searchPeople') : t('common.searchProducts')}
          </label>
          <input
            className="min-w-0 flex-1 border-0 bg-transparent px-3 py-[9px] text-ink"
            id="app-search"
            name="q"
            type="search"
            placeholder={
              searchScope === 'people' ? t('common.searchPeople') : t('common.searchProducts')
            }
          />
          <button
            type="button"
            className="flex w-[42px] flex-none cursor-pointer items-center justify-center border-0 border-l-[1.5px] border-ink bg-transparent p-0 text-ink hover:bg-surface-mid"
            onClick={() => setSearchScope(searchScope === 'people' ? 'products' : 'people')}
            aria-label={
              searchScope === 'people' ? t('common.searchPeople') : t('common.searchProducts')
            }
            title={searchScope === 'people' ? t('common.searchPeople') : t('common.searchProducts')}
          >
            <Icon name={searchScope === 'people' ? 'user' : 'sell'} size={16} />
          </button>
          <button
            className="flex w-[42px] flex-none cursor-pointer items-center justify-center border-0 bg-brand p-0 text-[22px] text-white"
            type="submit"
            aria-label={t('common.search')}
          >
            <Icon name="search" size={20} />
          </button>
        </form>
        <div className="ml-auto flex flex-none items-center gap-2.5 max-[760px]:gap-2 [&>div:last-child]:border [&>div:last-child]:p-0.5 [&>div:last-child]:before:inset-y-0.5  [&>div:last-child]:before:left-0.5 [&>div:last-child]:before:w-[calc((100%-4px)/var(--segment-count))] [&>div:last-child>button]:min-h-8 [&>div:last-child>button]:px-[7px] [&>div:last-child>button]:text-[11px] max-[760px]:[&>div:last-child>button]:min-h-7">
          <Link
            className="grid size-[38px] cursor-pointer place-items-center border border-ink bg-surface-mid text-ink max-[760px]:size-[34px]"
            to={to(paths.notifications)}
            aria-label={t('nav.notifications')}
          >
            <Icon name="bell" size={20} />
          </Link>
          <ThemeControl />
          <div className="relative" onBlur={dismiss} onKeyDown={escape}>
            <button
              className="grid size-[38px] cursor-pointer place-items-center overflow-hidden border border-ink bg-surface-mid p-0 max-[760px]:size-[34px]"
              type="button"
              onClick={() => setOpen(open === 'account' ? null : 'account')}
              aria-expanded={open === 'account'}
              aria-haspopup="menu"
              aria-label={user?.displayName ?? t('common.account')}
            >
              <Avatar
                src={user?.avatarUrl}
                name={user?.displayName ?? t('common.account')}
                size={38}
              />
            </button>
            {open === 'account'
              ? drop(
                  <>
                    <Link role="menuitem" to={to(paths.profile)} onClick={() => setOpen(null)}>
                      <Icon name="profile" size={16} />
                      {t('menu.profileView')}
                    </Link>
                    <Link role="menuitem" to={to(paths.editProfile)} onClick={() => setOpen(null)}>
                      <Icon name="pencil" size={16} />
                      {t('menu.editProfile')}
                    </Link>
                    <Link role="menuitem" to={to(paths.cart)} onClick={() => setOpen(null)}>
                      <Icon name="cart" size={16} />
                      {t('menu.cart')}
                    </Link>
                    <Link role="menuitem" to={to(paths.liked)} onClick={() => setOpen(null)}>
                      <Icon name="heart" size={16} />
                      {t('menu.likes')}
                    </Link>
                    <Link role="menuitem" to={to(paths.settings)} onClick={() => setOpen(null)}>
                      <Icon name="gear" size={16} />
                      {t('menu.settings')}
                    </Link>
                    <hr />
                    <button
                      type="button"
                      role="menuitem"
                      disabled={isSigningOut}
                      onClick={() => {
                        setOpen(null);
                        void signOut().catch(() => {});
                      }}
                    >
                      <Icon name="signOut" size={16} />
                      {t('menu.signOut')}
                    </button>
                  </>,
                  true,
                )
              : null}
          </div>
          <SegmentedControl<Locale>
            label={locale === 'en' ? 'Language' : 'Idioma'}
            value={locale}
            onChange={(next) => {
              if (next !== locale) void navigate(localeTarget(next));
            }}
            options={[
              { value: 'en', label: 'EN' },
              { value: 'pt-BR', label: 'PT-BR' },
            ]}
          />
        </div>
      </header>
      <main
        id="main-content"
        className="min-w-0 ml-(--sidebar-w) px-8 pt-6 pb-8 transition-[margin-left] duration-180 ease-linear group-data-[dragging=true]:transition-none group-data-[chat=true]:flex group-data-[chat=true]:min-h-0 group-data-[chat=true]:flex-1 group-data-[chat=true]:flex-col group-data-[chat=true]:overflow-hidden [&>div]:min-w-0 group-data-[chat=true]:[&>div]:flex group-data-[chat=true]:[&>div]:min-h-0 group-data-[chat=true]:[&>div]:flex-1 group-data-[chat=true]:[&>div]:flex-col max-[760px]:m-0 max-[760px]:px-4 max-[760px]:pt-4 max-[760px]:pb-[84px]"
      >
        {signOutFailed ? (
          <section
            className="grid justify-items-center gap-3.5 border border-(--hairline) bg-surface p-8 text-center"
            role="alert"
          >
            <p>{t('session.logoutFailed')}</p>
            <Button variant="secondary" onClick={() => void signOut().catch(() => {})}>
              {t('session.logoutRetry')}
            </Button>
          </section>
        ) : null}
        <div
          className="min-w-0 group-data-[chat=true]:flex group-data-[chat=true]:min-h-0 group-data-[chat=true]:flex-1 group-data-[chat=true]:flex-col"
          key={user?.id ?? 'signed-out'}
        >
          {children}
        </div>
      </main>
      <nav
        className="fixed inset-x-0 bottom-0 z-4 hidden justify-around bg-(--chrome) px-1 py-2 shadow-[0_-3px_var(--edge)] max-[760px]:flex max-[760px]:pb-[max(8px,env(safe-area-inset-bottom))]"
        aria-label={locale === 'en' ? 'Primary navigation' : 'Navegação principal'}
      >
        {primaryTabs.map(({ key, icon, title, href }) => (
          <Link
            key={key}
            className="flex flex-1 flex-col items-center gap-[3px] px-0.5 py-2.5 text-center font-display text-[10px] font-semibold hover:bg-surface-mid"
            to={to(href)}
            aria-current={isActive(href) ? 'page' : undefined}
          >
            <Icon name={icon} size={16} />
            {title}
          </Link>
        ))}
      </nav>
    </div>
  );
}
