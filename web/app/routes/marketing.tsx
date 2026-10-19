import { useLocation, useParams } from 'react-router';
import { appPath } from '../core/routes';
import { useI18n } from '../core/locale';
import { usePreferences } from '../core/preferences';

export default function MarketingRoute() {
  const { locale, path, t } = useI18n();
  const { pathname } = useLocation();
  const { locale: routeLocale } = useParams();
  const { theme, setTheme, animatedBackground, setAnimatedBackground } = usePreferences();
  if (routeLocale !== 'en' && routeLocale !== 'pt-BR') return <main id="main-content" className="not-found"><h1>404</h1><p>{t('marketing.notFound')}</p><a href="/pt-BR">Freebay</a></main>;
  const page = pathname.endsWith('/about') ? 'about' : pathname.endsWith('/how-it-works') ? 'how' : 'home';
  const title = page === 'home' ? t('marketing.title.home') : page === 'about' ? t('marketing.title.about') : t('marketing.title.how');
  const description = page === 'about' ? t('marketing.description.about') : t('marketing.description.home');
  const languagePath = appPath(locale === 'en' ? 'pt-BR' : 'en', page === 'home' ? '' : page === 'how' ? 'how-it-works' : 'about');

  return <>
    <header className="site-header">
      <a className="brand" href={path()} aria-label={t('marketing.brandHome')}><span className="brand-mark">f</span>freebay</a>
      <nav aria-label={locale === 'en' ? 'Main navigation' : 'Navegação principal'}>
        <a href={appPath(locale, 'explore')}>{t('nav.explore')}</a>
        <a href={appPath(locale, 'how-it-works')}>{t('marketing.secondary')}</a>
        <a href={appPath(locale, 'about')}>{t('marketing.nav.about')}</a>
      </nav>
      <div className="header-actions">
        <a className="quiet-link" href={appPath(locale, 'login')}>{t('marketing.signIn')}</a>
        <a className="button button-primary" href={appPath(locale, 'onboarding')}>{t('marketing.getStarted')}</a>
        <label className="pref-control"><span>{t('marketing.theme')}</span>
          <select value={theme} onChange={(event) => setTheme(event.currentTarget.value === 'dark' || event.currentTarget.value === 'light' ? event.currentTarget.value : 'system')} aria-label={t('marketing.theme')}>
            <option value="system">{t('marketing.theme.system')}</option><option value="light">{t('marketing.theme.light')}</option><option value="dark">{t('marketing.theme.dark')}</option>
          </select>
        </label>
        <button className="icon-control" onClick={() => setAnimatedBackground(!animatedBackground)} aria-pressed={animatedBackground} aria-label={t('marketing.animatedBackground')}>✳</button>
        <a className="locale-link" href={languagePath} lang={locale === 'en' ? 'pt-BR' : 'en'}>{locale === 'en' ? 'PT' : 'EN'}</a>
      </div>
    </header>
    <main className="hero" id="main-content">
      <div className="hero-copy">
        <p className="eyebrow"><span className="signal" />{t('marketing.eyebrow')}</p>
        <h1>{title}</h1><p className="hero-description">{description}</p>
        <form className="search-entry" action={appPath(locale, 'search')}>
          <label className="visually-hidden" htmlFor="market-search">{t('marketing.searchLabel')}</label>
          <input id="market-search" name="q" placeholder={t('marketing.searchPlaceholder')} />
          <button type="submit" aria-label={t('marketing.searchAction')}>⌕</button>
        </form>
        <div className="hero-actions">
          <a className="button button-primary" href={appPath(locale, 'explore')}>{t('marketing.primary')}<span aria-hidden="true">↗</span></a>
          <a className="button button-secondary" href={appPath(locale, 'how-it-works')}>{t('marketing.secondary')}</a>
        </div>
        <div className="hero-note"><span className="note-index">01</span><span>{t('marketing.note')}</span></div>
      </div>
      <div className="hero-art" role="img" aria-label={t('marketing.artLabel')}>
        <div className="art-orbit orbit-one" /><div className="art-orbit orbit-two" />
        <div className="art-sticker sticker-top">{t('marketing.artMadeForPeople')}</div>
        <div className="art-center"><span className="art-symbol">f</span><span className="art-center-caption">{t('marketing.artCommunity')}</span></div>
        <div className="art-card card-one"><span className="card-shape shape-one" /><span>{t('marketing.artStories')}</span></div>
        <div className="art-card card-two"><span className="card-shape shape-two" /><span>{t('marketing.artCirculation')}</span></div>
        <div className="art-sticker sticker-bottom">{t('marketing.artIntentionalFinds')}</div>
      </div>
    </main>
    <section className="below-fold">
      <div><span className="section-kicker">{t('marketing.sectionKicker')}</span><h2>{t('marketing.sectionTitle')}</h2></div>
      <p>{t('marketing.sectionDescription')}</p>
    </section>
    <footer><a className="brand" href={path()}><span className="brand-mark">f</span>freebay</a><span>{t('marketing.footer')}</span></footer>
  </>;
}
