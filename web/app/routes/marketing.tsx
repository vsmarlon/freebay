import { useLocation, useNavigate, useParams } from 'react-router';
import { appPath } from '../core/routes';
import { useI18n, type Locale } from '../core/locale';
import { BrandMark } from '../components/brand-mark';
import { Icon, SegmentedControl } from '../components';
import { ThemeControl } from '../components/theme-control';
import { FaqSections } from '../features/account/faq-sections';
import { useAccountText } from '../features/account/account';

type Page = 'home' | 'how' | 'about';
type TextFn = (key: string, values?: Record<string, string | number>) => string;

function Header({ locale, path, t, onLanguage }: { locale: Locale; path: (to?: string) => string; t: TextFn; onLanguage: (locale: Locale) => void }) {
  return <header className="site-header">
    <a className="brand" href={path()} aria-label={t('marketing.brandHome')}><BrandMark className="brand-mark" />freebay</a>
    <details className="relative sm:hidden">
      <summary className="icon-control cursor-pointer list-none" aria-label={locale === 'en' ? 'Main menu' : 'Menu principal'}><Icon name="menu" size={18} /></summary>
      <nav aria-label={locale === 'en' ? 'Main navigation' : 'Navegação principal'} className="absolute left-0 top-full z-20 grid min-w-56 gap-1 bg-surface-high p-2 shadow-[4px_4px_var(--edge)]">
        <a className="px-3 py-3 text-sm font-semibold" href={appPath(locale, 'explore')}>{t('nav.explore')}</a>
        <a className="px-3 py-3 text-sm font-semibold" href={appPath(locale, 'how-it-works')}>{t('marketing.secondary')}</a>
        <a className="px-3 py-3 text-sm font-semibold" href={appPath(locale, 'about')}>{t('marketing.nav.about')}</a>
      </nav>
    </details>
    <nav aria-label={locale === 'en' ? 'Main navigation' : 'Navegação principal'}>
      <a href={appPath(locale, 'explore')}>{t('nav.explore')}</a>
      <a href={appPath(locale, 'how-it-works')}>{t('marketing.secondary')}</a>
      <a href={appPath(locale, 'about')}>{t('marketing.nav.about')}</a>
    </nav>
    <div className="header-actions">
      <a className="quiet-link" href={appPath(locale, 'login')}>{t('marketing.signIn')}</a>
      <a className="button button-primary" href={appPath(locale, 'register')}>{t('marketing.getStarted')}</a>
      <ThemeControl />
      <SegmentedControl<Locale>
        label={locale === 'en' ? 'Language' : 'Idioma'}
        value={locale}
        onChange={onLanguage}
        options={[{ value: 'en', label: 'EN' }, { value: 'pt-BR', label: 'PT-BR' }]}
      />
    </div>
  </header>;
}

function Hero({ title, description, locale, t }: { title: string; description: string; locale: Locale; t: TextFn }) {
  return <main className="hero" id="main-content">
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
      <div className="art-center"><BrandMark className="art-symbol" /><span className="art-center-caption">{t('marketing.artCommunity')}</span></div>
      <div className="art-card card-one"><span className="card-shape shape-one" /><span>{t('marketing.artStories')}</span></div>
      <div className="art-card card-two"><span className="card-shape shape-two" /><span>{t('marketing.artCirculation')}</span></div>
      <div className="art-sticker sticker-bottom">{t('marketing.artIntentionalFinds')}</div>
    </div>
  </main>;
}

function Footer({ path, t }: { path: (to?: string) => string; t: TextFn }) {
  return <footer><a className="brand" href={path()}><BrandMark className="brand-mark" />freebay</a><span>{t('marketing.footer')}</span></footer>;
}

function HomeBody({ t }: { t: TextFn }) {
  return <section className="below-fold">
    <div><span className="section-kicker">{t('marketing.sectionKicker')}</span><h2>{t('marketing.sectionTitle')}</h2></div>
    <p>{t('marketing.sectionDescription')}</p>
  </section>;
}

function HowBody({ faqTitle }: { faqTitle: string }) {
  return <section className="mx-auto grid w-full max-w-4xl gap-6 px-6 pb-16">
    <h2 className="font-display text-2xl font-bold">{faqTitle}</h2>
    <div className="grid gap-5"><FaqSections /></div>
  </section>;
}

function AboutBody({ locale, t }: { locale: Locale; t: TextFn }) {
  const account = useAccountText();
  return <section className="mx-auto grid w-full max-w-4xl gap-10 px-6 pb-16">
    <div className="grid gap-3 border-t-2 border-ink pt-6">
      <h2 className="font-display text-2xl font-bold">{t('marketing.about.whatTitle')}</h2>
      <p className="max-w-prose text-muted">{t('marketing.sectionDescription')}</p>
    </div>
    <div className="grid gap-3 border-t-2 border-ink pt-6">
      <h2 className="font-display text-2xl font-bold">{t('marketing.about.escrowTitle')}</h2>
      <p className="max-w-prose text-muted">{account.t('faqEscrowAnswer')}</p>
    </div>
    <div className="grid gap-3 border-t-2 border-ink pt-6">
      <h2 className="font-display text-2xl font-bold">{t('marketing.about.sellingTitle')}</h2>
      <p className="max-w-prose text-muted">{account.t('faqPayoutAnswer')}</p>
      <p className="max-w-prose text-muted">{account.t('faqSellingFeeAnswer')}</p>
    </div>
    <div className="grid gap-3 border-t-2 border-ink pt-6">
      <h2 className="font-display text-2xl font-bold">{t('marketing.about.safetyTitle')}</h2>
      <p className="max-w-prose text-muted">{account.t('faqSecureChatAnswer')}</p>
      <p className="max-w-prose text-muted">{account.t('faqBankDataAnswer')}</p>
    </div>
    <p><a className="button button-primary" href={appPath(locale, 'explore')}>{t('marketing.primary')}</a></p>
  </section>;
}

export default function MarketingRoute() {
  const { locale, path, t } = useI18n();
  const { pathname } = useLocation();
  const { locale: routeLocale } = useParams();
  if (routeLocale !== 'en' && routeLocale !== 'pt-BR') return <main id="main-content" className="not-found"><h1>404</h1><p>{t('marketing.notFound')}</p><a href="/pt-BR">Freebay</a></main>;
  const page: Page = pathname.endsWith('/about') ? 'about' : pathname.endsWith('/how-it-works') ? 'how' : 'home';
  const title = page === 'home' ? t('marketing.title.home') : page === 'about' ? t('marketing.title.about') : t('marketing.title.how');
  const description = page === 'about' ? t('marketing.description.about') : page === 'how' ? t('marketing.description.how') : t('marketing.description.home');
  const pagePath = page === 'home' ? '' : page === 'how' ? 'how-it-works' : 'about';
  const navigate = useNavigate();

  return <>
    <Header locale={locale} path={path} t={t} onLanguage={(next) => { if (next !== locale) navigate(appPath(next, pagePath)); }} />
    <Hero title={title} description={description} locale={locale} t={t} />
    {page === 'home' ? <HomeBody t={t} /> : page === 'how' ? <HowBody faqTitle={t('marketing.how.faqTitle')} /> : <AboutBody locale={locale} t={t} />}
    <Footer path={path} t={t} />
  </>;
}
