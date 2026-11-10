import { createContext, useContext, useMemo } from 'react';
import en from './catalogs/en.json';
import pt from './catalogs/pt-BR.json';

export type Locale = 'pt-BR' | 'en';
export type Catalogs = Record<Locale, Record<string, string>>;
type LocaleValue = { locale: Locale; path: (relativePath?: string) => string };
const LocaleContext = createContext<LocaleValue>({
  locale: 'pt-BR',
  path: (relative = '') => `/pt-BR${relative ? `/${relative}` : ''}`,
});
export function LocaleProvider({ locale, children }: React.PropsWithChildren<{ locale: Locale }>) {
  return (
    <LocaleContext.Provider
      value={{
        locale,
        path: (relative = '') => `/${locale}${relative ? `/${relative.replace(/^\/+/, '')}` : ''}`,
      }}
    >
      {children}
    </LocaleContext.Provider>
  );
}
export function useLocale() {
  return useContext(LocaleContext);
}
const base: Catalogs = { en, 'pt-BR': pt };
export function translator(catalogs: Catalogs, locale: Locale) {
  const t = (key: string, values: Record<string, string | number> = {}) => {
    let text = catalogs[locale][key] ?? base[locale][key] ?? key;
    for (const [name, value] of Object.entries(values))
      text = text.replaceAll(`{${name}}`, String(value));
    return text;
  };
  return t;
}
export function useI18n(catalogs: Catalogs = base) {
  const { locale, path } = useLocale();
  const t = useMemo(() => translator(catalogs, locale), [catalogs, locale]);
  return { locale, path, t };
}
