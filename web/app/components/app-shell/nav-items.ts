import { useLocation } from 'react-router';
import { useI18n } from '../../core/locale';
import { appPath, paths } from '../../core/routes';

// One navigation model shared by the sidebar, the mobile menu dropdown and the
// bottom bar, so the three lists and the active-link rule cannot drift apart.
export function useNav() {
  const { locale, t } = useI18n();
  const location = useLocation();
  const to = (href: string) => appPath(locale, href);
  const isActive = (href: string) => location.pathname === (href ? to(href) : `/${locale}`);
  const primary = [
    { key: 'home', icon: 'home', title: t('nav.home'), href: paths.feed },
    { key: 'explore', icon: 'explore', title: t('nav.explore'), href: paths.explore },
    { key: 'sell', icon: 'sell', title: t('nav.sell'), href: paths.sell },
    { key: 'messages', icon: 'messages', title: t('nav.messages'), href: paths.messages },
    { key: 'profile', icon: 'profile', title: t('nav.profile'), href: paths.profile },
  ] as const;
  const sidebar = [
    ...primary,
    { key: 'wallet', icon: 'wallet', title: t('nav.wallet'), href: paths.wallet },
    { key: 'settings', icon: 'gear', title: t('menu.settings'), href: paths.settings },
  ] as const;
  return { locale, t, to, isActive, primary, sidebar };
}
