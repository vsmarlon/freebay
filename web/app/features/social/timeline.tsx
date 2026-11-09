import { buttonClass } from '../../components';
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
  if (query.isPending) return <div className="grid gap-3 [&>span]:h-14 [&>span]:animate-[shimmer_1000ms_linear_infinite_alternate] [&>span]:bg-surface-mid" aria-label={t('common.loading')}><span /><span /></div>;
  if (query.isError || query.isFetchNextPageError) return <section role="alert" className="grid justify-items-center gap-3.5 border border-(--hairline) bg-surface p-8 text-center"><p>{t('common.error')}</p><button className={buttonClass('secondary')} onClick={() => void query.refetch()}>{t('common.retry')}</button></section>;
  if (!entries.length) return <section className="border border-(--hairline) bg-surface p-8 text-center">{t('social.empty.feed')}</section>;
  return <section className="grid gap-4">{entries.map((entry) => <div key={`${entry.post.id}:${entry.repostId ?? 'post'}`} className="grid gap-2">{entry.repostedBy ? <p className="text-xs font-bold text-muted">↻ {entry.repostedBy.displayName} · {t('social.post.repost')}</p> : null}<PostCard post={entry.post} /></div>)}{query.hasNextPage ? <button className={`${buttonClass('secondary')} justify-self-center`} disabled={query.isFetchingNextPage} onClick={() => void query.fetchNextPage()}>{query.isFetchingNextPage ? t('common.loading') : t('social.loadMore')}</button> : null}</section>;
}
