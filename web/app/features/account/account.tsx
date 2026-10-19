import { useState, type FormEvent, type PropsWithChildren } from 'react';
import { Link, useLocation, useParams } from 'react-router';
import { ApiError } from '../../core/api';
import { paths, pathsFor } from '../../core/routes';
import { useLocale } from '../../core/locale';
import { RequireAuth, useSession } from '../../core/session';
import enCatalog from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

export type User = { id: string; displayName: string; username: string | null; avatarUrl: string | null; bannerUrl?: string | null; bio?: string | null; city?: string | null; state?: string | null; isVerified?: boolean; postsCount?: number; productsCount?: number; followersCount?: number; followingCount?: number; hasCpf?: boolean; deletionRequestedAt?: string | null };
export function useAccountText() {
  const { locale, path } = useLocale();
  const isEnglish = locale === 'en';
  const t = (key: string, values: Record<string, string | number> = {}) => Object.entries(values).reduce((text, [name, value]) => text.replaceAll(`{${name}}`, String(value)), (isEnglish ? enCatalog : ptBR)[key as keyof typeof enCatalog] ?? key);
  return { locale, path, t };
}

export function Frame({ title, children, publicPage = false }: PropsWithChildren<{ title: string; publicPage?: boolean }>) {
  const { t, path } = useAccountText();
  const content = <div className="mx-auto min-h-screen w-full max-w-5xl px-4 py-8 text-ink sm:px-8"><header className="mb-8 flex flex-wrap items-center justify-between gap-4"><Link to={path('feed')} className="font-display text-xl font-black">FREEBAY</Link><nav className="flex flex-wrap gap-4 text-sm"><Link to={path(paths.profile)}>{t('profile')}</Link><Link to={path(paths.search)}>{t('people')}</Link><Link to={path(paths.notifications)}>{t('notifications')}</Link><Link to={path(paths.settings)}>{t('settings')}</Link></nav></header><h1 className="mb-6 font-display text-3xl font-bold">{title}</h1>{children}</div>;
  return publicPage ? content : <RequireAuth>{content}</RequireAuth>;
}
export function Panel({ children }: PropsWithChildren) { return <section className="bg-surface p-4 text-ink sm:p-6">{children}</section>; }
export function ErrorText({ error }: { error: unknown }) { return <p role="alert" className="text-danger">{error instanceof ApiError ? error.message : 'Request failed.'}</p>; }
export function PersonLink({ user }: { user: User }) { const { path } = useAccountText(); return <Link className="font-semibold underline" to={path(pathsFor.person(user.id))}>{user.displayName}{user.username ? ` @${user.username}` : ''}</Link>; }
export function PersonCard({ user, action }: { user: User; action?: React.ReactNode }) { return <div className="flex min-w-0 items-center justify-between gap-4 bg-surface-mid p-3"><div className="flex min-w-0 items-center gap-3"><img className="h-12 w-12 bg-surface-high object-cover" src={user.avatarUrl || undefined} alt="" /><div className="min-w-0"><PersonLink user={user} /><p className="truncate text-sm text-secondary">{user.bio}</p></div></div>{action}</div>; }
export function useFormSubmit(run: () => Promise<void>) { const [pending, setPending] = useState(false); const [error, setError] = useState(false); const submit = async (event: FormEvent) => { event.preventDefault(); setPending(true); setError(false); try { await run(); } catch { setError(true); } finally { setPending(false); } }; return { submit, pending, error }; }
export function useCurrentUser() { return useSession(); }
export function useAccountParams() { return useParams(); }
export function useAccountLocation() { return useLocation(); }
