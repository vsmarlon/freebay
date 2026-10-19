import type { LinksFunction, MetaFunction } from 'react-router';
import { Links, Meta, Outlet, Scripts, ScrollRestoration, useLocation } from 'react-router';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState } from 'react';
import { LocaleProvider } from './core/locale';
import { PreferencesProvider } from './core/preferences';
import { Aurora } from './components/aurora';
import { SessionProvider } from './core/session';
import './styles.css';

export const meta: MetaFunction = ({ location }) => location.pathname.startsWith('/en')
  ? [{ title: 'Freebay — a community marketplace for good finds' }, { name: 'description', content: 'Discover products, people, and good stories with the Freebay community.' }]
  : [{ title: 'Freebay — comunidade que encontra bons achados' }, { name: 'description', content: 'Descubra produtos, pessoas e boas histórias na comunidade Freebay.' }];
export const links: LinksFunction = () => [{ rel: 'preload', href: '/fonts/SpaceGrotesk[wght].ttf', as: 'font', type: 'font/ttf', crossOrigin: 'anonymous' }, { rel: 'preload', href: '/fonts/Inter[opsz,wght].ttf', as: 'font', type: 'font/ttf', crossOrigin: 'anonymous' }];

export function Layout({ children }: Readonly<{ children: React.ReactNode }>) {
  const locale = useLocation().pathname.split('/')[1] === 'en' ? 'en' : 'pt-BR';
  return <html lang={locale} data-theme="light" suppressHydrationWarning><head><meta charSet="utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1" /><Meta /><Links /><script dangerouslySetInnerHTML={{ __html: `(()=>{try{const p=JSON.parse(localStorage.getItem('freebay.preferences')||'{}');const t=p.theme||'system';document.documentElement.dataset.theme=t==='system'?(matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light'):t;document.documentElement.dataset.aurora=p.animatedBackground===false?'off':'on'}catch{}})()` }} /></head><body>{children}<ScrollRestoration /><Scripts /></body></html>;
}

export default function App() { const locale = useLocation().pathname.split('/')[1] === 'en' ? 'en' : 'pt-BR'; const [queryClient] = useState(() => new QueryClient()); return <QueryClientProvider client={queryClient}><SessionProvider><LocaleProvider locale={locale}><PreferencesProvider><a className="skip-link" href="#main-content">Skip to content</a><Aurora /><Outlet /></PreferencesProvider></LocaleProvider></SessionProvider></QueryClientProvider>; }
