import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';
import { useI18n, type Catalogs } from '../../core/locale';
import { appPath, paths, safeLocalizedReturnTo } from '../../core/routes';
import { completeOnboarding } from '../../core/session';

const catalogs: Catalogs = { en, 'pt-BR': pt };
const slides = [
  { tag: 'step.1', title: 'title.1', body: 'body.1', highlights: ['highlight.1a', 'highlight.1b', 'highlight.1c'] },
  { tag: 'step.2', title: 'title.2', body: 'body.2', highlights: ['highlight.2a', 'highlight.2b', 'highlight.2c'] },
  { tag: 'step.3', title: 'title.3', body: 'body.3', highlights: ['highlight.3a', 'highlight.3b', 'highlight.3c'] },
] as const;

export default function Onboarding() {
  const { locale, t } = useI18n(catalogs);
  const navigate = useNavigate();
  const location = useLocation();
  const [index, setIndex] = useState(0);
  const finish = () => {
    completeOnboarding();
    const returnTo = new URLSearchParams(location.search).get('returnTo');
    const login = appPath(locale, paths.login);
    navigate(returnTo ? `${login}?returnTo=${encodeURIComponent(safeLocalizedReturnTo(returnTo, locale))}` : login, { replace: true });
  };
  const slide = slides[index];
  return <main className="onboarding" aria-labelledby="onboarding-title">
    <header><Link className="brand" to={`/${locale}`}><span className="brand-mark">f</span>freebay</Link><button type="button" className="onboarding-skip" onClick={finish}>{t('skip')}</button></header>
    <section aria-live="polite" className="onboarding-slide">
      <div className="onboarding-mark" aria-hidden="true">{['▧', '◉', '¤'][index]}</div>
      <p className="onboarding-step">{t(slide.tag)}</p><h1 id="onboarding-title">{t(slide.title)}</h1><p>{t(slide.body)}</p>
      <ul>{slide.highlights.map((key) => <li key={key}>{t(key)}</li>)}</ul>
    </section>
    <footer><progress value={index + 1} max={slides.length} aria-label={t('progress', { current: index + 1, total: slides.length })} />
      <button type="button" className="button button-primary" onClick={() => index === slides.length - 1 ? finish() : setIndex(index + 1)}>{index === slides.length - 1 ? t('finish') : t('next')} <span aria-hidden="true">→</span></button>
    </footer>
  </main>;
}
