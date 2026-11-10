import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';
import { Button } from '../../components';
import { BrandMark } from '../../components/brand-mark';
import { useI18n, type Catalogs } from '../../core/locale';
import { appPath, paths, safeLocalizedReturnTo } from '../../core/routes';
import { completeWelcome, RequireAuth, useSession } from '../../core/session';

const catalogs: Catalogs = { en, 'pt-BR': pt };

function WelcomeSetup() {
  const { locale, t } = useI18n(catalogs);
  const { user } = useSession();
  const location = useLocation();
  const navigate = useNavigate();
  const [step, setStep] = useState(0);
  const finish = (destination?: string) => {
    if (!user) return;
    completeWelcome(user.id);
    const requested = new URLSearchParams(location.search).get('returnTo');
    navigate(destination ?? safeLocalizedReturnTo(requested, locale), { replace: true });
  };
  const titles = ['welcome.title.1', 'welcome.title.2', 'welcome.title.3'] as const;
  const bodies = ['welcome.body.1', 'welcome.body.2', 'welcome.body.3'] as const;
  return (
    <main
      className="mx-auto flex min-h-svh max-w-[820px] flex-col p-6"
      aria-labelledby="welcome-title"
    >
      <header className="flex items-center justify-between gap-4">
        <Link
          className="inline-flex items-center gap-[9px] font-display text-[21px] font-bold tracking-[-1px] text-ink"
          to={appPath(locale)}
        >
          <BrandMark className="block size-7 shrink-0 text-[#660062]" />
          freebay
        </Link>
        <button
          type="button"
          className="min-h-10 cursor-pointer border border-ink bg-surface px-3 text-ink"
          onClick={() => finish()}
        >
          {t('skip')}
        </button>
      </header>
      <section
        className="flex flex-1 flex-col items-center justify-center text-center"
        aria-live="polite"
      >
        <div
          className="grid size-[120px] place-items-center bg-[#660062] font-display text-[60px] font-bold text-white"
          aria-hidden="true"
        >
          {step === 2 ? <BrandMark className="block size-16 text-white" /> : ['✓', '⚙'][step]}
        </div>
        <p className="font-display text-xs font-bold text-brand">
          {t('welcome.step', { current: step + 1, total: 3 })}
        </p>
        <h1 id="welcome-title" className="font-display text-[clamp(30px,7vw,48px)] font-bold">
          {t(titles[step])}
        </h1>
        <p className="max-w-[560px] text-muted">{t(bodies[step])}</p>
        {step === 1 ? (
          <Link
            className="min-h-10 border border-ink bg-surface px-3 py-2 text-ink"
            to={appPath(locale, paths.settings)}
            onClick={() => completeWelcome(user!.id)}
          >
            {t('welcome.settings')}
          </Link>
        ) : null}
      </section>
      <footer className="flex items-center justify-end gap-4 pt-6">
        <progress
          className="mr-auto accent-brand"
          value={step + 1}
          max={3}
          aria-label={t('welcome.step', { current: step + 1, total: 3 })}
        />
        <Button onClick={() => (step === 2 ? finish() : setStep(step + 1))}>
          {step === 2 ? t('finish') : t('next')}
        </Button>
      </footer>
    </main>
  );
}

export default function WelcomeRoute() {
  return (
    <RequireAuth>
      <WelcomeSetup />
    </RequireAuth>
  );
}
