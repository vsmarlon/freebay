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
  return <main className="onboarding" aria-labelledby="welcome-title">
    <header><Link className="brand" to={appPath(locale)}><BrandMark className="brand-mark" />freebay</Link><button type="button" className="onboarding-skip" onClick={() => finish()}>{t('skip')}</button></header>
    <section className="onboarding-slide" aria-live="polite">
      <div className="onboarding-mark" aria-hidden="true">{step === 2 ? <BrandMark className="onboarding-mark-icon" /> : ['✓', '⚙'][step]}</div>
      <p className="onboarding-step">{t('welcome.step', { current: step + 1, total: 3 })}</p>
      <h1 id="welcome-title">{t(titles[step])}</h1><p>{t(bodies[step])}</p>
      {step === 1 ? <Link className="button button-secondary" to={appPath(locale, paths.settings)} onClick={() => completeWelcome(user!.id)}>{t('welcome.settings')}</Link> : null}
    </section>
    <footer><progress value={step + 1} max={3} aria-label={t('welcome.step', { current: step + 1, total: 3 })} />
      <Button onClick={() => step === 2 ? finish() : setStep(step + 1)}>{step === 2 ? t('finish') : t('next')}</Button>
    </footer>
  </main>;
}

export default function WelcomeRoute() { return <RequireAuth><WelcomeSetup /></RequireAuth>; }
