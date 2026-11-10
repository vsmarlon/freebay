import type { LinksFunction, MetaFunction } from 'react-router';
import { Links, Meta, Outlet, Scripts, ScrollRestoration, useLocation } from 'react-router';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useSyncExternalStore, useState } from 'react';
import { LocaleProvider } from './core/locale';
import interLatinUrl from './fonts/inter-var-latin.woff2?url';
import spaceGroteskLatinUrl from './fonts/space-grotesk-var-latin.woff2?url';
import { Aurora } from './components/aurora';
import { ToastProvider } from './components/toast';
import { SessionProvider } from './core/session';
import './styles.css';

export const meta: MetaFunction = ({ location }) =>
  location.pathname.startsWith('/en')
    ? [
        { title: 'Freebay — a community marketplace for good finds' },
        {
          name: 'description',
          content: 'Discover products, people, and good stories with the Freebay community.',
        },
      ]
    : [
        { title: 'Freebay — comunidade que encontra bons achados' },
        {
          name: 'description',
          content: 'Descubra produtos, pessoas e boas histórias na comunidade Freebay.',
        },
      ];
export const links: LinksFunction = () => [
  { rel: 'icon', href: '/favicon.svg', type: 'image/svg+xml' },
  { rel: 'preload', href: interLatinUrl, as: 'font', type: 'font/woff2', crossOrigin: 'anonymous' },
  {
    rel: 'preload',
    href: spaceGroteskLatinUrl,
    as: 'font',
    type: 'font/woff2',
    crossOrigin: 'anonymous',
  },
];

function createQueryClient() {
  const client = new QueryClient({ defaultOptions: { queries: { refetchOnWindowFocus: false } } });
  client.getQueryCache().subscribe((event) => {
    if (event.type !== 'removed') return;
    const url = event.query.state.data;
    if (event.query.queryKey[0] === 'media' && typeof url === 'string') {
      try {
        URL.revokeObjectURL(url);
      } catch {
        /* ignore */
      }
    }
  });
  return client;
}

export function Layout({ children }: Readonly<{ children: React.ReactNode }>) {
  const { pathname } = useLocation();
  const segments = pathname.split('/').filter(Boolean);
  const locale = segments[0] === 'en' ? 'en' : 'pt-BR';
  const route = segments.slice(segments[0] === 'en' || segments[0] === 'pt-BR' ? 1 : 0);
  const storyViewer =
    route[0] === 'highlights' ||
    (route[0] === 'stories' &&
      route.length === 2 &&
      !['new', 'mine', 'archive'].includes(route[1]));
  const hydrated = useSyncExternalStore(
    () => () => {},
    () => true,
    () => false,
  );
  return (
    <html
      lang={locale}
      data-theme="light"
      data-hydrated={hydrated ? 'true' : undefined}
      suppressHydrationWarning
    >
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <Meta />
        <Links />
        <script>{`(()=>{try{const p=JSON.parse(localStorage.getItem('freebay.preferences')||'{}');const t=p.theme||'system';document.documentElement.dataset.theme=t==='system'?(matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light'):t;document.documentElement.dataset.aurora=p.animatedBackground===false?'off':'on'}catch{}})();(()=>{let s;addEventListener('scroll',()=>{document.documentElement.dataset.scrolling='true';clearTimeout(s);s=setTimeout(()=>{delete document.documentElement.dataset.scrolling},1200)},{passive:true,capture:true})})()`}</script>
      </head>
      <body className={storyViewer ? 'overflow-hidden' : undefined}>
        {children}
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  );
}

export default function App() {
  const locale = useLocation().pathname.split('/')[1] === 'en' ? 'en' : 'pt-BR';
  const [queryClient] = useState(() => createQueryClient());
  return (
    <QueryClientProvider client={queryClient}>
      <SessionProvider>
        <LocaleProvider locale={locale}>
          <a
            className="absolute left-[-9999px] top-0 z-20 bg-white p-2.5 focus:left-2"
            href="#main-content"
          >
            Skip to content
          </a>
          <Aurora />
          <ToastProvider>
            <Outlet />
          </ToastProvider>
        </LocaleProvider>
      </SessionProvider>
    </QueryClientProvider>
  );
}
