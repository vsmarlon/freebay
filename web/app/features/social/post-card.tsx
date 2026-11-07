import { useState } from 'react';
import { Link } from 'react-router';
import { useSession } from '../../core/session';
import { pathsFor } from '../../core/routes';
import { useI18n } from '../../core/locale';
import { useSocialActions } from './queries';
import { PostMediaCarousel } from './post-media';
import { Button, Dialog, Icon } from '../../components';
import type { Post, PostAudience, ReportReason } from './types';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': ptBR };
const reasons: ReportReason[] = ['FALSE_ADVERTISING', 'SPAM', 'FRAUD', 'NUDITY', 'HARASSMENT', 'OTHER', 'FAKE_ACCOUNT', 'IMPERSONATING', 'BLACKMAIL'];
const openDialog = (id: string) => { const dialog = document.getElementById(id); if (dialog instanceof HTMLDialogElement) dialog.showModal(); };
const closeDialog = (id: string) => { const dialog = document.getElementById(id); if (dialog instanceof HTMLDialogElement) dialog.close(); };
export const canRepostPost = (audience: PostAudience) => audience === 'EVERYONE';

export function PostCard({ post, onChanged }: { post: Post; onChanged?: () => void }) {
  const session = useSession();
  const { t, path, locale } = useI18n(catalogs);
  const userId = session.user?.id ?? '';
  const actions = useSocialActions(userId);
  const [error, setError] = useState(false);
  const [reported, setReported] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [reportTarget, setReportTarget] = useState<'POST' | 'USER'>('POST');
  const [reason, setReason] = useState<ReportReason>('SPAM');
  const [description, setDescription] = useState('');
  const mine = post.userId === userId;
  async function act(run: () => Promise<unknown>) { setError(false); try { await run(); onChanged?.(); } catch { setError(true); } }
  if (post.audience === 'CLOSE_FRIENDS' && !userId) return <article className="surface grid gap-3"><p>{t('social.loginPrompt')}</p><Link className="ui-button ui-primary justify-self-start" to={path('login')}>{t('social.signIn')}</Link></article>;
  return <article className="surface grid gap-4" aria-label={`${post.user.displayName} post`}>
    <header className="flex items-center gap-3">
      <Link to={path(pathsFor.person(post.userId))} aria-label={post.user.displayName} className="shrink-0">
        {post.user.avatarUrl ? <img className="avatar size-11 object-cover" src={post.user.avatarUrl} alt="" /> : <span aria-hidden="true" className="avatar grid size-11 place-items-center font-display text-lg font-bold">{post.user.displayName.slice(0, 1).toUpperCase()}</span>}
      </Link>
      <div className="min-w-0 flex-1"><Link className="font-display font-bold hover:text-brand" to={path(pathsFor.person(post.userId))}>{post.user.displayName}{post.user.isVerified ? ' ✓' : ''}</Link><p className="text-xs text-muted">@{post.user.username ?? post.user.id.slice(0, 8)} · <time dateTime={post.createdAt}>{new Intl.DateTimeFormat(locale, { dateStyle: 'medium' }).format(new Date(post.createdAt))}</time></p></div>
      {post.audience === 'CLOSE_FRIENDS' ? <span className="status">{t('social.post.private')}</span> : null}
      <details className="relative"><summary className="ui-button ui-sm ui-ghost cursor-pointer list-none" aria-label={userId ? t('social.post.report') : t('social.loginPrompt')}>•••</summary><div className="absolute right-0 z-10 grid min-w-40 gap-2 bg-surface-high p-2 shadow-[4px_4px_var(--edge)]">
        {!userId ? <Link className="ui-button ui-ghost" to={path('login')}>{t('social.loginPrompt')}</Link> : !mine ? <><button className="ui-button ui-ghost" onClick={() => { setReportTarget('POST'); openDialog(`report-${post.id}`); }}>{t('social.post.report')}</button><button className="ui-button ui-ghost" onClick={() => { setReportTarget('USER'); openDialog(`report-${post.id}`); }}>{t('social.post.reportAuthor')}</button></> : <button className="ui-button ui-danger" onClick={() => setDeleteOpen(true)}>{t('social.post.delete')}</button>}
      </div></details>
    </header>
    {post.content ? <p className="whitespace-pre-wrap break-words text-[15px] leading-7">{post.content}</p> : null}
    <PostMediaCarousel items={post.media ?? []} fallbackAlt={post.content ?? ''} />
    {post.product ? <Link className="surface-mid grid gap-1 p-4" to={path(pathsFor.product(post.product.id))}><span className="text-xs font-bold uppercase tracking-wider text-muted">{t('social.post.product')}</span><strong className="font-display text-lg">{post.product.title}</strong><span className="font-display font-bold">{new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(post.product.price / 100)}</span></Link> : null}
    <nav aria-label={t('social.post.open')} className="post-actions">
      {userId
        ? <button className="post-action" aria-pressed={post.isLiked} onClick={() => void act(() => (post.isLiked ? actions.unlike : actions.like).mutateAsync(post.id))} aria-label={post.isLiked ? t('social.post.unlike') : t('social.post.like')}><Icon name="heart" size={19} /><span>{post.likesCount}</span></button>
        : <Link className="post-action" to={path('login')} aria-label={t('social.post.like')}><Icon name="heart" size={19} /><span>{post.likesCount}</span></Link>}
      <Link className="post-action" to={path(pathsFor.post(post.id))} aria-label={t('social.post.comments')}><Icon name="comment" size={19} /><span>{post.commentsCount}</span></Link>
      {userId
        ? canRepostPost(post.audience)
          ? <button className="post-action" aria-pressed={post.hasReposted} onClick={() => void act(() => (post.hasReposted ? actions.unshare : actions.repost).mutateAsync(post.id))} aria-label={post.hasReposted ? t('social.post.unrepost') : t('social.post.repost')}><Icon name="repeat" size={19} /><span>{post.sharesCount}</span></button>
          : null
        : <Link className="post-action" to={path('login')} aria-label={t('social.post.repost')}><Icon name="repeat" size={19} /><span>{post.sharesCount}</span></Link>}
      {userId
        ? <button className="post-action post-action-end" aria-pressed={post.isSaved} onClick={() => void act(() => (post.isSaved ? actions.unsave : actions.save).mutateAsync(post.id))} aria-label={post.isSaved ? t('social.post.unsave') : t('social.post.save')}><Icon name="bookmark" size={19} /></button>
        : <Link className="post-action post-action-end" to={path('login')} aria-label={t('social.post.save')}><Icon name="bookmark" size={19} /></Link>}
    </nav>
    {error ? <p role="alert" className="status status-error">{t('social.post.actionError')}</p> : null}
    {!mine ? <dialog id={`report-${post.id}`} className="ui-dialog"><form method="dialog" onSubmit={(event) => { event.preventDefault(); void act(async () => { await actions.report.mutateAsync({ type: reportTarget, id: reportTarget === 'POST' ? post.id : post.userId, reason, description }); setReported(true); closeDialog(`report-${post.id}`); }); }}><h2 className="font-display text-xl font-bold">{reportTarget === 'POST' ? t('social.report.title') : t('social.post.reportAuthor')}</h2><label className="ui-field mt-4">{t('social.report.reason')}<select value={reason} onChange={(event) => setReason(event.currentTarget.value as ReportReason)}>{reasons.map((value) => <option key={value} value={value}>{t(`social.report.${({ SPAM: 'spam', FRAUD: 'fraud', NUDITY: 'nudity', HARASSMENT: 'harassment', FALSE_ADVERTISING: 'falseAdvertising', OTHER: 'other', FAKE_ACCOUNT: 'fakeAccount', IMPERSONATING: 'impersonating', BLACKMAIL: 'blackmail' })[value]}`)}</option>)}</select></label><label className="ui-field mt-3">{t('social.report.description')}<textarea rows={3} maxLength={1000} value={description} onChange={(event) => setDescription(event.currentTarget.value)} /></label><footer className="flex"><button className="ui-button ui-ghost" type="button" onClick={() => closeDialog(`report-${post.id}`)}>{t('common.cancel')}</button><button className="ui-button ui-primary" type="submit">{t('social.report.submit')}</button></footer></form></dialog> : null}
    <Dialog open={deleteOpen} onClose={() => setDeleteOpen(false)} title={t('social.post.delete')} actions={<><Button variant="secondary" onClick={() => setDeleteOpen(false)}>{t('common.cancel')}</Button><Button variant="danger" onClick={() => { setDeleteOpen(false); void act(async () => { await actions.deletePost.mutateAsync(post.id); }); }}>{t('social.post.delete')}</Button></>}>{t('social.post.confirmDelete')}</Dialog>
    {reported ? <p role="status" className="text-sm">{t('social.post.reported')}</p> : null}
  </article>;
}
