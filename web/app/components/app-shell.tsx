import { Link } from 'react-router';
import { useI18n } from '../core/locale';
import { paths, appPath } from '../core/routes';
import { usePreferences } from '../core/preferences';
import { useSession } from '../core/session';
import { Avatar, Button } from './index';

export function AppShell({ children }: React.PropsWithChildren) {
  const { locale, t } = useI18n();
  const { user, signOutFailed, signOut } = useSession();
  const { theme, setTheme, animatedBackground, setAnimatedBackground } = usePreferences();
  const tabs = [
    { key: 'home', title: t('nav.home'), href: paths.feed },
    { key: 'explore', title: t('nav.explore'), href: paths.explore },
    { key: 'sell', title: t('nav.sell'), href: paths.sell },
    { key: 'messages', title: t('nav.messages'), href: paths.messages },
    { key: 'profile', title: t('nav.profile'), href: paths.profile },
  ];

  return <div className="app-shell">
    <aside className="app-sidebar">
      <Link className="brand" to={`/${locale}`}><span className="brand-mark">f</span>freebay</Link>
      <nav aria-label={locale === 'en' ? 'Primary navigation' : 'Navegação principal'}>
        {tabs.map(({ key, title, href }) => <Link key={key} to={appPath(locale, href)}>{title}</Link>)}
      </nav>
    </aside>
    <header className="app-topbar">
      <Link className="app-topbar-brand brand" to={`/${locale}`}><span className="brand-mark">f</span></Link>
      <form className="app-search" action={appPath(locale, paths.search)}>
        <label className="visually-hidden" htmlFor="app-search">{t('common.search')}</label>
        <input id="app-search" name="q" type="search" placeholder={t('common.search')} />
        <button type="submit" aria-label={t('common.search')}>⌕</button>
      </form>
      <Link className="app-action" to={appPath(locale, paths.notifications)} aria-label={t('nav.notifications')}><svg aria-hidden="true" viewBox="0 0 24 24" width="20" height="20"><path d="M18 9a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" fill="none" stroke="currentColor" strokeWidth="2" /></svg></Link>
      <label className="app-theme"><span className="visually-hidden">{t('marketing.theme')}</span>
        <select value={theme} onChange={(event) => setTheme(event.currentTarget.value === 'dark' || event.currentTarget.value === 'light' ? event.currentTarget.value : 'system')} aria-label={t('marketing.theme')}>
          <option value="system">{t('marketing.theme.system')}</option><option value="light">{t('marketing.theme.light')}</option><option value="dark">{t('marketing.theme.dark')}</option>
        </select>
      </label>
      <button className="app-action" onClick={() => setAnimatedBackground(!animatedBackground)} aria-pressed={animatedBackground} aria-label={t('marketing.animatedBackground')}>✳</button>
      <Link className="app-account" to={appPath(locale, paths.profile)} aria-label={user?.displayName ?? t('common.account')}>
        <Avatar src={user?.avatarUrl} name={user?.displayName ?? t('common.account')} size={38} />
      </Link>
      <Link className="app-locale" to={appPath(locale === 'en' ? 'pt-BR' : 'en', paths.feed)} lang={locale === 'en' ? 'pt-BR' : 'en'}>{locale === 'en' ? 'PT' : 'EN'}</Link>
    </header>
    <main id="main-content" className="app-content">
      {signOutFailed ? <section className="error-state" role="alert"><p>{t('session.logoutFailed')}</p><Button variant="secondary" onClick={() => void signOut().catch(() => {})}>{t('session.logoutRetry')}</Button></section> : null}
      <div key={user?.id ?? 'signed-out'}>{children}</div>
    </main>
    <nav className="mobile-tabs" aria-label={locale === 'en' ? 'Primary navigation' : 'Navegação principal'}>
      {tabs.map(({ key, title, href }) => <Link key={key} to={appPath(locale, href)}>{title}</Link>)}
    </nav>
  </div>;
}
