import type { ButtonHTMLAttributes, InputHTMLAttributes, PropsWithChildren, ReactNode } from 'react';
import { Link, useLocation } from 'react-router';
import { useI18n, type Catalogs } from '../../core/locale';
import { Button, Input, Status } from '../../components';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs: Catalogs = { en, 'pt-BR': ptBR };

export function useAuthText() {
  const shared = useI18n();
  return {
    ...shared,
    t: (key: string, values?: Record<string, string | number>) => catalogs[shared.locale][key] ?? shared.t(key, values),
  };
}

export function AuthFrame({ title, description, children, footer }: PropsWithChildren<{ title: string; description: string; footer?: ReactNode }>) {
  const { locale, path, t } = useAuthText();
  const location = useLocation();
  const localizedRoute = location.pathname.replace(/^\/(pt-BR|en)\/?/, '');
  return (
    <main className="min-h-screen bg-surface text-ink">
      <div className="mx-auto flex min-h-screen w-full max-w-6xl flex-col px-5 py-6 sm:px-8">
        <header className="flex items-center justify-between">
          <Link to={path()} className="font-display text-xl font-black tracking-tight">{t('auth.brand')}</Link>
          <nav aria-label={locale === 'en' ? 'Language' : 'Idioma'} className="flex gap-3 text-sm">
            <Link to={`/pt-BR${localizedRoute ? `/${localizedRoute}` : ''}`} lang="pt-BR" hrefLang="pt-BR">PT</Link>
            <Link to={`/en${localizedRoute ? `/${localizedRoute}` : ''}`} lang="en" hrefLang="en">EN</Link>
          </nav>
        </header>
        <section className="mx-auto my-auto w-full max-w-md py-12" aria-labelledby="auth-title">
          <p className="mb-3 text-sm font-bold tracking-widest text-brand">FREEBAY / ACCOUNT</p>
          <h1 id="auth-title" className="font-display text-4xl font-bold tracking-tight">{title}</h1>
          <p className="mt-3 text-muted">{description}</p>
          <div className="mt-8">{children}</div>
          {footer ? <div className="mt-6 text-sm text-muted">{footer}</div> : null}
        </section>
        <footer className="py-4 text-xs text-muted">Freebay · {locale}</footer>
      </div>
    </main>
  );
}

export function AuthMessage({ children, error = false }: PropsWithChildren<{ error?: boolean }>) {
  return <p role={error ? 'alert' : 'status'} aria-live="polite" className="mt-4 text-sm"><Status tone={error ? 'error' : 'success'}>{children}</Status></p>;
}

export function AuthInput({ label, ...props }: InputHTMLAttributes<HTMLInputElement> & { label: string }) {
  return <Input label={label} {...props} />;
}

export function AuthButton({ children, ...props }: ButtonHTMLAttributes<HTMLButtonElement>) {
  return <Button variant="primary" className="w-full" {...props}>{children}</Button>;
}
