import { useState, useSyncExternalStore } from 'react';
import type { KeyboardEvent, PointerEvent as ReactPointerEvent } from 'react';
import { Link } from 'react-router';
import { Icon } from '../index';
import { BrandMark } from '../brand-mark';
import { useNav } from './nav-items';

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

function persistSidebar(next: SidebarPrefs) {
  try {
    localStorage.setItem(storageKey, JSON.stringify(next));
  } catch {
    /* storage can be disabled */
  }
}

const clampWidth = (value: number) =>
  Math.min(SIDEBAR_MAX, Math.max(SIDEBAR_MIN, Math.round(value)));

// Width/collapse state lives here rather than in the shell because the drag handle,
// the collapse toggle and the persisted preference are a single concern; the shell
// only reads the derived width to set --sidebar-w and the data attributes.
export function useSidebar() {
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

  const commitWidth = (value: number) => {
    const nextWidth = clampWidth(value);
    setWidth(nextWidth);
    persistSidebar({ width: nextWidth, collapsed });
  };
  const toggleCollapsed = () => {
    setCollapsed((current) => {
      const next = !current;
      persistSidebar({ width, collapsed: next });
      return next;
    });
  };

  // Drag-resizable expanded sidebar: drag the right edge or use arrows on it; collapsed rails do nothing until expanded again.
  const expandSidebar = () => {
    setCollapsed(false);
    persistSidebar({ width, collapsed: false });
  };
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

  return {
    width,
    collapsed,
    dragging,
    effectiveWidth: collapsed ? SIDEBAR_COLLAPSED : width,
    toggleCollapsed,
    onDragStart,
    onHandleKeyDown,
  };
}

export type SidebarControls = ReturnType<typeof useSidebar>;

export function Sidebar({ controls }: { controls: SidebarControls }) {
  const { locale, t, to, isActive, sidebar } = useNav();
  const { width, collapsed, toggleCollapsed, onDragStart, onHandleKeyDown } = controls;
  return (
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
        {sidebar.map(({ key, icon, title, href }) => (
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
  );
}
