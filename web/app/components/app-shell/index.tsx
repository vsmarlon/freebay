import { useState } from 'react';
import { useLocation } from 'react-router';
import { useI18n } from '../../core/locale';
import { useSession } from '../../core/session';
import { Button } from '../index';
import { BottomNav } from './bottom-nav';
import { Sidebar, useSidebar } from './sidebar';
import { TopBar, type ShellMenu } from './top-bar';

export function AppShell({ children }: React.PropsWithChildren) {
  const { t } = useI18n();
  const location = useLocation();
  const { user, signOutFailed, signOut } = useSession();
  const sidebar = useSidebar();
  // One owner for both dropdowns: opening the account menu closes the mobile nav.
  const [menu, setMenu] = useState<ShellMenu>(null);
  const chatThread = location.pathname
    .split('/')
    .filter(Boolean)
    .some((segment, index, segments) => segment === 'messages' && segments.length - index === 2);
  const sidebarVar = { '--sidebar-w': `${sidebar.effectiveWidth}px` } as React.CSSProperties;

  return (
    <div
      className="group min-h-svh [--sidebar-w:240px] data-[chat=true]:flex data-[chat=true]:h-svh data-[chat=true]:flex-col data-[dragging=true]:cursor-col-resize data-[dragging=true]:select-none"
      data-chat={chatThread ? 'true' : undefined}
      data-collapsed={sidebar.collapsed ? 'true' : 'false'}
      data-dragging={sidebar.dragging ? 'true' : undefined}
      style={sidebarVar}
    >
      <Sidebar controls={sidebar} />
      <TopBar menu={menu} setMenu={setMenu} />
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
      <BottomNav />
    </div>
  );
}
