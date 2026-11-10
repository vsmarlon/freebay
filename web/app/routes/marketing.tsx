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

function Header({
  locale,
  path,
  t,
  onLanguage,
}: {
  locale: Locale;
  path: (to?: string) => string;
  t: TextFn;
  onLanguage: (locale: Locale) => void;
}) {
  return (
    <header className="mx-auto flex h-20 max-w-[1440px] items-center gap-12 px-10 max-[900px]:gap-5 max-[900px]:px-[22px] max-[640px]:h-16 max-[640px]:gap-2.5 max-[640px]:px-4">
      <a
        className="inline-flex items-center gap-[9px] font-display text-[21px] font-bold tracking-[-1px] max-[640px]:text-lg"
        href={path()}
        aria-label={t('marketing.brandHome')}
      >
        <BrandMark className="block size-7 shrink-0 text-[#660062] max-[640px]:size-[25px]" />
        freebay
      </a>
      <details className="relative sm:hidden">
        <summary
          className="icon-control cursor-pointer list-none"
          aria-label={locale === 'en' ? 'Main menu' : 'Menu principal'}
        >
          <Icon name="menu" size={18} />
        </summary>
        <nav
          aria-label={locale === 'en' ? 'Main navigation' : 'Navegação principal'}
          className="absolute left-0 top-full z-20 grid min-w-56 gap-1 bg-surface-high p-2 shadow-[4px_4px_var(--edge)]"
        >
          <a className="p-3  text-sm font-semibold" href={appPath(locale, 'explore')}>
            {t('nav.explore')}
          </a>
          <a className="p-3  text-sm font-semibold" href={appPath(locale, 'how-it-works')}>
            {t('marketing.secondary')}
          </a>
          <a className="p-3  text-sm font-semibold" href={appPath(locale, 'about')}>
            {t('marketing.nav.about')}
          </a>
        </nav>
      </details>
      <nav
        aria-label={locale === 'en' ? 'Main navigation' : 'Navegação principal'}
        className="flex flex-1 items-center gap-[26px] max-[900px]:gap-[15px] max-[640px]:hidden"
      >
        <a href={appPath(locale, 'explore')}>{t('nav.explore')}</a>
        <a href={appPath(locale, 'how-it-works')}>{t('marketing.secondary')}</a>
        <a href={appPath(locale, 'about')}>{t('marketing.nav.about')}</a>
      </nav>
      <div className="ml-auto flex items-center gap-[14px] max-[900px]:gap-[9px] max-[640px]:flex-wrap max-[640px]:justify-end max-[640px]:gap-2">
        <a
          className="text-xs font-semibold hover:text-brand max-[640px]:hidden"
          href={appPath(locale, 'login')}
        >
          {t('marketing.signIn')}
        </a>
        <a
          className="inline-flex min-h-11 items-center justify-center gap-3 bg-linear-to-br from-[#660062] to-brand px-[18px] font-display text-[15px] font-bold text-white shadow-[3px_3px_#660062] transition-[transform,box-shadow] duration-120 active:translate-[3px]  active:shadow-none max-[640px]:min-h-9 max-[640px]:px-[11px]"
          href={appPath(locale, 'register')}
        >
          {t('marketing.getStarted')}
        </a>
        <ThemeControl />
        <SegmentedControl<Locale>
          label={locale === 'en' ? 'Language' : 'Idioma'}
          value={locale}
          onChange={onLanguage}
          options={[
            { value: 'en', label: 'EN' },
            { value: 'pt-BR', label: 'PT-BR' },
          ]}
        />
      </div>
    </header>
  );
}

function Hero({
  title,
  description,
  locale,
  t,
}: {
  title: string;
  description: string;
  locale: Locale;
  t: TextFn;
}) {
  return (
    <main
      className="mx-auto grid min-h-[calc(100svh-150px)] max-w-[1440px] grid-cols-[1.08fr_.92fr] items-center gap-[5vw] px-[8vw] py-[7vh] pb-[9vh] max-[900px]:gap-[2vw] max-[900px]:px-[6vw] max-[900px]:py-[6vh] max-[640px]:min-h-0 max-[640px]:flex max-[640px]:flex-col max-[640px]:items-stretch max-[640px]:gap-[25px] max-[640px]:px-[22px] max-[640px]:pt-[8vh] max-[640px]:pb-[5vh]"
      id="main-content"
    >
      <div className="relative z-1 max-w-[640px]">
        <p className="font-display text-[11px] font-bold tracking-[.14em]">
          <span className="mr-2.5 inline-block size-2 bg-brand" />
          {t('marketing.eyebrow')}
        </p>
        <h1 className="my-[25px] max-w-[720px] font-display text-[clamp(48px,6.1vw,56px)] font-extrabold leading-[.95] tracking-[-2px] max-[640px]:my-5 max-[640px]:text-[clamp(48px,14vw,56px)]">
          {title}
        </h1>
        <p className="max-w-[440px] text-base leading-[1.65] text-muted max-[640px]:text-sm">
          {description}
        </p>
        <form
          className="mt-[22px] flex max-w-[440px] bg-surface shadow-[3px_3px_var(--edge)] ring-1 ring-inset ring-ink"
          action={appPath(locale, 'search')}
        >
          <label className="sr-only" htmlFor="market-search">
            {t('marketing.searchLabel')}
          </label>
          <input
            className="min-w-0 flex-1 bg-transparent p-3 text-ink outline-none"
            id="market-search"
            name="q"
            placeholder={t('marketing.searchPlaceholder')}
          />
          <button
            className="w-12 cursor-pointer border-0 bg-brand text-2xl text-white"
            type="submit"
            aria-label={t('marketing.searchAction')}
          >
            ⌕
          </button>
        </form>
        <div className="mt-[30px] flex gap-[14px] max-[640px]:flex-wrap">
          <a
            className="inline-flex min-h-11 items-center justify-center gap-3 bg-linear-to-br from-[#660062] to-brand px-[18px] font-display text-[15px] font-bold text-white shadow-[3px_3px_#660062] transition-[transform,box-shadow] duration-120 active:translate-[3px]  active:shadow-none"
            href={appPath(locale, 'explore')}
          >
            {t('marketing.primary')}
            <span aria-hidden="true">↗</span>
          </a>
          <a
            className="inline-flex min-h-11 items-center justify-center gap-3 border-[1.5px] border-ink bg-surface px-[18px] font-display text-[15px] font-bold text-ink"
            href={appPath(locale, 'how-it-works')}
          >
            {t('marketing.secondary')}
          </a>
        </div>
        <div className="mt-10 flex items-center gap-[14px] bg-surface p-3 text-xs text-muted max-[640px]:mt-6">
          <span className="font-display text-[11px] font-bold text-brand">01</span>
          <span>{t('marketing.note')}</span>
        </div>
      </div>
      <div
        className="relative mx-auto grid aspect-square w-full max-w-[540px] place-items-center max-[640px]:w-[min(85vw,400px)]"
        role="img"
        aria-label={t('marketing.artLabel')}
      >
        <div className="absolute inset-[8%_4%] rotate-[-22deg] border-[1.5px] border-ink/45" />
        <div className="absolute inset-y-[19%] inset-x-0 rotate-37 border-[1.5px] border-ink/45" />
        <div className="absolute right-[8%] top-[7%] rotate-[8deg] bg-[#ff9dee] px-[11px] py-2 font-display text-[9px] font-bold leading-[1.2] tracking-widest text-[#11100e]">
          {t('marketing.artMadeForPeople')}
        </div>
        <div className="flex aspect-square w-[48%] rotate-[-5deg] flex-col items-center justify-center bg-[#660062] text-white shadow-[3px_3px_#8a1083]">
          <BrandMark className="block size-[132px] shrink-0 text-white max-[900px]:size-24 max-[640px]:size-24" />
          <span className="mt-5 font-display text-[9px] font-bold leading-[1.4] tracking-[.16em]">
            {t('marketing.artCommunity')}
          </span>
        </div>
        <div className="absolute left-[3%] top-[18%] flex rotate-[-7deg] items-center gap-3 bg-surface p-[14px] font-display text-xs font-bold leading-[1.2] shadow-[3px_3px_var(--edge)] max-[640px]:gap-2 max-[640px]:p-2.5 max-[640px]:text-[10px]">
          <span className="block size-[42px] bg-[repeating-linear-gradient(45deg,#8a1083_0_6px,#ff9dee_6px_12px)] max-[640px]:size-8" />
          <span>{t('marketing.artStories')}</span>
        </div>
        <div className="absolute right-[1%] bottom-[18%] flex rotate-6 items-center gap-3 bg-surface p-[14px] font-display text-xs font-bold leading-[1.2] shadow-[3px_3px_var(--edge)] max-[640px]:gap-2 max-[640px]:p-2.5 max-[640px]:text-[10px]">
          <span className="block size-[42px] bg-[linear-gradient(135deg,#f59e0b_0_45%,#11100e_45%_55%,#10b981_55%)] max-[640px]:size-8" />
          <span>{t('marketing.artCirculation')}</span>
        </div>
        <div className="absolute bottom-[8%] left-[7%] rotate-[-5deg] bg-[#ff9dee] px-[11px] py-2 font-display text-[9px] font-bold leading-[1.2] tracking-widest text-[#11100e]">
          {t('marketing.artIntentionalFinds')}
        </div>
      </div>
    </main>
  );
}

function Footer({ path, t }: { path: (to?: string) => string; t: TextFn }) {
  return (
    <footer className="mx-auto flex max-w-[1440px] items-center justify-between px-10 py-[25px] text-[11px] text-muted max-[640px]:flex-col max-[640px]:items-start max-[640px]:gap-5 max-[640px]:p-5">
      <a
        className="inline-flex items-center gap-[9px] font-display text-[21px] font-bold tracking-[-1px] max-[640px]:text-lg"
        href={path()}
      >
        <BrandMark className="block size-7 shrink-0 text-[#660062] max-[640px]:size-[25px]" />
        freebay
      </a>
      <span>{t('marketing.footer')}</span>
    </footer>
  );
}

function HomeBody({ t }: { t: TextFn }) {
  return (
    <section className="mx-auto mb-[60px] grid max-w-[1250px] grid-cols-2 items-end gap-[50px] bg-surface px-[8vw] py-[35px] max-[640px]:mx-4 max-[640px]:mb-[25px] max-[640px]:mt-[15px] max-[640px]:block max-[640px]:p-6">
      <div>
        <span className="font-display text-[11px] font-bold tracking-[.14em]">
          {t('marketing.sectionKicker')}
        </span>
        <h2 className="mt-4 max-w-[540px] font-display text-[clamp(30px,4vw,48px)] font-bold leading-[1.02] tracking-tighter">
          {t('marketing.sectionTitle')}
        </h2>
      </div>
      <p className="mb-[5px] max-w-[430px] text-muted max-[640px]:mt-5">
        {t('marketing.sectionDescription')}
      </p>
    </section>
  );
}

function HowBody({ faqTitle }: { faqTitle: string }) {
  return (
    <section className="mx-auto grid w-full max-w-4xl gap-6 px-6 pb-16">
      <h2 className="font-display text-2xl font-bold">{faqTitle}</h2>
      <div className="grid gap-5">
        <FaqSections />
      </div>
    </section>
  );
}

function AboutBody({ locale, t }: { locale: Locale; t: TextFn }) {
  const account = useAccountText();
  return (
    <section className="mx-auto grid w-full max-w-4xl gap-10 px-6 pb-16">
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
      <p>
        <a
          className="inline-flex min-h-11 items-center justify-center gap-3 bg-linear-to-br from-[#660062] to-brand px-[18px] font-display text-[15px] font-bold text-white shadow-[3px_3px_#660062] transition-[transform,box-shadow] duration-120 active:translate-[3px]  active:shadow-none"
          href={appPath(locale, 'explore')}
        >
          {t('marketing.primary')}
        </a>
      </p>
    </section>
  );
}

export default function MarketingRoute() {
  const { locale, path, t } = useI18n();
  const { pathname } = useLocation();
  const { locale: routeLocale } = useParams();
  const navigate = useNavigate();
  if (routeLocale !== 'en' && routeLocale !== 'pt-BR')
    return (
      <main id="main-content" className="p-[10vh] text-center">
        <h1>404</h1>
        <p>{t('marketing.notFound')}</p>
        <a href="/pt-BR">Freebay</a>
      </main>
    );
  const page: Page = pathname.endsWith('/about')
    ? 'about'
    : pathname.endsWith('/how-it-works')
      ? 'how'
      : 'home';
  const title =
    page === 'home'
      ? t('marketing.title.home')
      : page === 'about'
        ? t('marketing.title.about')
        : t('marketing.title.how');
  const description =
    page === 'about'
      ? t('marketing.description.about')
      : page === 'how'
        ? t('marketing.description.how')
        : t('marketing.description.home');
  const pagePath = page === 'home' ? '' : page === 'how' ? 'how-it-works' : 'about';

  return (
    <>
      <Header
        locale={locale}
        path={path}
        t={t}
        onLanguage={(next) => {
          if (next !== locale) navigate(appPath(next, pagePath));
        }}
      />
      <Hero title={title} description={description} locale={locale} t={t} />
      {page === 'home' ? (
        <HomeBody t={t} />
      ) : page === 'how' ? (
        <HowBody faqTitle={t('marketing.how.faqTitle')} />
      ) : (
        <AboutBody locale={locale} t={t} />
      )}
      <Footer path={path} t={t} />
    </>
  );
}
