import {
  type ButtonHTMLAttributes,
  type InputHTMLAttributes,
  type PropsWithChildren,
  type ReactNode,
} from 'react';
import { Link, useLocation, useNavigate } from 'react-router';
import { useI18n, type Catalogs, type Locale } from '../../core/locale';
import {
  Button,
  Input,
  PasswordInput,
  SegmentedControl,
  Status,
  type IconName,
} from '../../components';
import { BrandMark } from '../../components/brand-mark';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs: Catalogs = { en, 'pt-BR': ptBR };

export function useAuthText() {
  return useI18n(catalogs);
}

export function AuthFrame({
  title,
  description,
  children,
  footer,
}: PropsWithChildren<{ title: string; description: string; footer?: ReactNode }>) {
  const { locale, path, t } = useAuthText();
  const location = useLocation();
  const navigate = useNavigate();
  const localizedRoute = location.pathname.replace(/^\/(pt-BR|en)\/?/, '');
  return (
    <main className="min-h-screen text-ink">
      <div className="mx-auto flex min-h-screen w-full max-w-6xl flex-col px-5 py-6 sm:px-8">
        <header className="flex items-center justify-between">
          <Link
            to={path()}
            className="flex items-center gap-2 font-display text-xl font-black tracking-tight"
          >
            <BrandMark className="size-6 text-[#660062]" />
            {t('auth.brand')}
          </Link>
          <div className="[&>div]:border [&>div]:p-0.5 [&>div]:before:inset-y-0.5  [&>div]:before:left-0.5 [&>div]:before:w-[calc((100%-4px)/var(--segment-count))] [&_button]:min-h-8 [&_button]:px-2.5 [&_button]:text-xs">
            <SegmentedControl<Locale>
              label={locale === 'en' ? 'Language' : 'Idioma'}
              value={locale}
              onChange={(next) => {
                if (next !== locale)
                  void navigate(`/${next}${localizedRoute ? `/${localizedRoute}` : ''}`);
              }}
              options={[
                { value: 'en', label: 'EN' },
                { value: 'pt-BR', label: 'PT-BR' },
              ]}
            />
          </div>
        </header>
        <section className="m-auto  w-full max-w-md py-12" aria-labelledby="auth-title">
          <h1 id="auth-title" className="font-display text-4xl font-bold tracking-tight">
            {title}
          </h1>
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
  return (
    <p role={error ? 'alert' : 'status'} aria-live="polite" className="mt-4 text-sm">
      <Status tone={error ? 'error' : 'success'}>{children}</Status>
    </p>
  );
}

export function AuthInput({
  label,
  icon,
  ...props
}: InputHTMLAttributes<HTMLInputElement> & { label: string; icon?: IconName }) {
  return <Input label={label} icon={icon} {...props} />;
}

export function AuthPassword({
  label,
  ...props
}: InputHTMLAttributes<HTMLInputElement> & { label: string }) {
  return <PasswordInput label={label} {...props} />;
}

export function AuthButton({ children, ...props }: ButtonHTMLAttributes<HTMLButtonElement>) {
  return (
    <Button variant="primary" className="w-full" {...props}>
      {children}
    </Button>
  );
}
