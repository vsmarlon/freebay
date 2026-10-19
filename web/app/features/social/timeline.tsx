import { useSession } from '../../core/session';
import { useI18n } from '../../core/locale';
import { useTimeline } from './queries';
import { PostCard } from './post-card';
import type { TimelineKind } from './types';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': ptBR };
export function Timeline({ userId, kind = 'all' }: { userId: string; kind?: 'post' | 'repost' | 'product' | 'all' }) {
  const session = useSession(); const { t } = useI18n(catalogs); const scope: TimelineKind = kind; const query = useTimeline(session.user?.id ?? '', userId, scope);
  const entries = query.data?.pages.flatMap((page) => page.items) ?? [];
  if (query.isPending) return <div className="loading-list" aria-label={t('common.loading')}><span /><span /></div>;
  if (query.isError || query.isFetchNextPageError) return <section role="alert" className="error-state"><p>{t('common.error')}</p><button className="ui-button ui-secondary" onClick={() => void query.refetch()}>{t('common.retry')}</button></section>;
  if (!entries.length) return <section className="empty-state">{t('social.empty.feed')}</section>;
  return <section className="grid gap-4">{entries.map((entry) => <div key={`${entry.post.id}:${entry.repostId ?? 'post'}`} className="grid gap-2">{entry.repostedBy ? <p className="text-xs font-bold text-muted">↻ {entry.repostedBy.displayName} · {t('social.post.repost')}</p> : null}<PostCard post={{ ...entry.post, isReposted: entry.isReposted, hasReposted: entry.post.hasReposted || entry.isReposted, sharesCount: entry.sharesCount }} /></div>)}{query.hasNextPage ? <button className="ui-button ui-secondary justify-self-center" disabled={query.isFetchingNextPage} onClick={() => void query.fetchNextPage()}>{query.isFetchingNextPage ? t('common.loading') : t('social.loadMore')}</button> : null}</section>;
}
