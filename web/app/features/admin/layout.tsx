import { NavLink, Outlet } from 'react-router';
import { Icon, PageHeader } from '../../components';
import { useI18n } from '../../core/locale';
import { appPath, paths } from '../../core/routes';
import { useSession } from '../../core/session';

export default function AdminLayout() {
  const { user, isPending } = useSession();
  const { locale } = useI18n();
  const pt = locale === 'pt-BR';

  if (isPending) return <p role="status">{pt ? 'Carregando…' : 'Loading…'}</p>;

  if (!user || user.role !== 'ADMIN') {
    return (
      <section role="alert" className="border border-(--hairline) bg-surface p-8 text-center">
        <h1>{pt ? 'Acesso restrito' : 'Restricted access'}</h1>
        <p>{pt ? 'Esta área é exclusiva da moderação.' : 'This area is for moderators only.'}</p>
      </section>
    );
  }

  const tab = (to: string, label: string, icon: 'shield' | 'doc') => (
    <NavLink
      to={to}
      end
      className={({ isActive }) =>
        `inline-flex min-h-10 items-center gap-2 border border-ink px-3.5 font-display text-[13px] font-bold ${
          isActive ? 'bg-brand text-white' : 'bg-surface text-ink hover:bg-surface-high'
        }`
      }
    >
      <Icon name={icon} /> {label}
    </NavLink>
  );

  return (
    <section className="grid gap-6">
      <PageHeader
        title={pt ? 'Administração' : 'Admin'}
        description={pt ? 'Fila de disputas e denúncias.' : 'Disputes and reports queue.'}
      />
      <nav
        aria-label={pt ? 'Seções de administração' : 'Admin sections'}
        className="flex flex-wrap gap-2"
      >
        {tab(appPath(locale, paths.admin), pt ? 'Disputas' : 'Disputes', 'shield')}
        {tab(appPath(locale, paths.adminReports), pt ? 'Denúncias' : 'Reports', 'doc')}
      </nav>
      <Outlet />
    </section>
  );
}
