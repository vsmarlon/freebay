import { useState } from 'react';
import type { FocusEvent, KeyboardEvent, ReactNode } from 'react';
import { Link, useLocation, useNavigate } from 'react-router';
import type { Locale } from '../../core/locale';
import { paths } from '../../core/routes';
import { useSession } from '../../core/session';
import { Avatar, Icon, SegmentedControl } from '../index';
import { BrandMark } from '../brand-mark';
import { ThemeControl } from '../theme-control';
import { useNav } from './nav-items';
import { useScrollChrome } from './use-scroll-chrome';

export type ShellMenu = 'nav' | 'account' | null;

export function TopBar({ menu, setMenu }: { menu: ShellMenu; setMenu: (next: ShellMenu) => void }) {
  const { locale, t, to, isActive, sidebar } = useNav();
  const location = useLocation();
  const navigate = useNavigate();
  const { user, isSigningOut, signOut } = useSession();
  const [searchScope, setSearchScope] = useState<'products' | 'people'>('products');
  const scrollChrome = useScrollChrome();
  // Dropdown dismissal without effects: blur leaves only when focus jumps outside the wrapper, Escape closes on bubble.
  const dismiss = (event: FocusEvent<HTMLDivElement>) => {
    if (
      !(event.relatedTarget instanceof Node) ||
      !event.currentTarget.contains(event.relatedTarget)
    )
      setMenu(null);
  };
  const escape = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === 'Escape') setMenu(null);
  };
  // The locale switch preserves the current route by swapping only the locale segment.
  const localeTarget = (next: 'en' | 'pt-BR') =>
    `/${next}${location.pathname.replace(/^\/(en|pt-BR)(?=\/|$)/, '')}${location.search}`;
  // Shared menu frame for the nav and account dropdowns; `end` anchors it to the right edge.
  const drop = (entries: ReactNode, end = false) => (
    <div
      className={`absolute top-[calc(100%+6px)] z-6 grid min-w-[230px] gap-0.5 border-[1.5px] border-ink bg-surface p-2 shadow-[4px_4px_var(--edge)] max-[760px]:inset-x-[10px]  max-[760px]:min-w-0 ${end ? 'left-auto right-0 ' : 'left-0'}`}
      role="menu"
      onBlur={dismiss}
    >
      {entries}
    </div>
  );

  return (
    <header
      ref={scrollChrome}
      className="sticky top-0 z-3 ml-(--sidebar-w) flex min-h-[72px] items-center gap-2.5 border-b border-[#ff9dee] bg-(--chrome) px-7 py-3 transition-[margin-left,transform] duration-180 ease-linear data-[chrome-hidden=true]:pointer-events-none data-[chrome-hidden=true]:-translate-y-full group-data-[dragging=true]:transition-none group-data-[chat=true]:flex-none max-[760px]:m-0 max-[760px]:min-h-[58px] max-[760px]:flex-wrap max-[760px]:gap-[7px] max-[760px]:px-[14px] max-[760px]:py-2.5"
    >
      <div className="relative hidden max-[760px]:block" onBlur={dismiss} onKeyDown={escape}>
        <button
          className="grid size-[38px] cursor-pointer place-items-center border border-ink bg-surface-mid text-ink max-[760px]:size-[34px] max-[760px]:bg-surface-mid"
          type="button"
          onClick={() => setMenu(menu === 'nav' ? null : 'nav')}
          aria-expanded={menu === 'nav'}
          aria-haspopup="menu"
          aria-label={t('nav.menu')}
        >
          <Icon name={menu === 'nav' ? 'close' : 'menu'} size={20} />
        </button>
        {menu === 'nav'
          ? drop(
              sidebar.map(({ key, icon, title, href }) => (
                <Link
                  key={key}
                  role="menuitem"
                  className={`flex w-full items-center gap-2.5 px-3 py-2.5 font-display text-[13px] font-semibold text-ink hover:bg-surface-mid ${isActive(href) ? 'bg-surface-mid shadow-[2px_2px_var(--edge)]' : ''}`}
                  to={to(href)}
                  onClick={() => setMenu(null)}
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
            onClick={() => setMenu(menu === 'account' ? null : 'account')}
            aria-expanded={menu === 'account'}
            aria-haspopup="menu"
            aria-label={user?.displayName ?? t('common.account')}
          >
            <Avatar
              src={user?.avatarUrl}
              name={user?.displayName ?? t('common.account')}
              size={38}
            />
          </button>
          {menu === 'account'
            ? drop(
                <>
                  <Link role="menuitem" to={to(paths.profile)} onClick={() => setMenu(null)}>
                    <Icon name="profile" size={16} />
                    {t('menu.profileView')}
                  </Link>
                  <Link role="menuitem" to={to(paths.editProfile)} onClick={() => setMenu(null)}>
                    <Icon name="pencil" size={16} />
                    {t('menu.editProfile')}
                  </Link>
                  <Link role="menuitem" to={to(paths.cart)} onClick={() => setMenu(null)}>
                    <Icon name="cart" size={16} />
                    {t('menu.cart')}
                  </Link>
                  <Link role="menuitem" to={to(paths.liked)} onClick={() => setMenu(null)}>
                    <Icon name="heart" size={16} />
                    {t('menu.likes')}
                  </Link>
                  <Link role="menuitem" to={to(paths.settings)} onClick={() => setMenu(null)}>
                    <Icon name="gear" size={16} />
                    {t('menu.settings')}
                  </Link>
                  <hr />
                  <button
                    type="button"
                    role="menuitem"
                    disabled={isSigningOut}
                    onClick={() => {
                      setMenu(null);
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
  );
}
