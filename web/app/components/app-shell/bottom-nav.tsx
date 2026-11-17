import { Link } from 'react-router';
import { Icon } from '../index';
import { useNav } from './nav-items';

export function BottomNav() {
  const { locale, to, isActive, primary } = useNav();
  return (
    <nav
      className="fixed inset-x-0 bottom-0 z-4 hidden justify-around bg-(--chrome) px-1 py-2 shadow-[0_-3px_var(--edge)] max-[760px]:flex max-[760px]:pb-[max(8px,env(safe-area-inset-bottom))]"
      aria-label={locale === 'en' ? 'Primary navigation' : 'Navegação principal'}
    >
      {primary.map(({ key, icon, title, href }) => (
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
  );
}
