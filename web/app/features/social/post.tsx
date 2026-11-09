import { useState, type FormEvent } from 'react';
import { Link, useParams } from 'react-router';
import { useSession, RequireAuth } from '../../core/session';
import { useI18n } from '../../core/locale';
import { pathsFor } from '../../core/routes';
import { socialApi } from './data';
import { useComments, usePost, useSocialActions } from './queries';
import { PostCard } from './post-card';
import { Button, ComposerInput, Dialog, buttonClass } from '../../components';
import { canApproveComment, type Comment } from './types';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': ptBR };
const COMMENT_LIMIT = 280;
const COMMENT_WARNING_THRESHOLD = 20;
const commentGraphemeCount = (value: string) => [...new Intl.Segmenter(undefined, { granularity: 'grapheme' }).segment(value)].length;

function CommentRow({ comment, postId, userId, postOwnerId, parentIsHidden = false, depth = 0 }: { comment: Comment; postId: string; userId: string; postOwnerId: string; parentIsHidden?: boolean; depth?: number }) {
  const { t, path, locale } = useI18n(catalogs); const actions = useSocialActions(userId); const [reply, setReply] = useState(''); const [replying, setReplying] = useState(false); const [error, setError] = useState(false); const [deleteOpen, setDeleteOpen] = useState(false); const [likePending, setLikePending] = useState(false);
  const replyLength = commentGraphemeCount(reply);
  async function submit(event: FormEvent) { event.preventDefault(); if (!reply.trim() || commentGraphemeCount(reply) > COMMENT_LIMIT) return; setError(false); try { await actions.createComment.mutateAsync({ id: postId, content: reply.trim(), parentId: comment.id }); setReply(''); setReplying(false); } catch { setError(true); } }
  async function toggleLike() { if (likePending) return; setLikePending(true); setError(false); try { const state = await socialApi.likeComment(comment.id, comment.isLiked); actions.patchComments(comment.id, { isLiked: state.active, likesCount: state.count }); } catch { setError(true); } finally { setLikePending(false); } }
  return <article className={`grid gap-2 bg-surface-mid p-3 ${depth ? 'ml-4 sm:ml-8' : ''}`}>
    <header className="flex items-center gap-2 text-sm"><Link className="font-bold" to={path(pathsFor.person(comment.userId))}>{comment.user?.displayName ?? t('social.post.anonymous')}</Link><time className="text-xs text-muted" dateTime={comment.createdAt}>{new Intl.DateTimeFormat(locale, { dateStyle: 'medium' }).format(new Date(comment.createdAt))}</time></header>
    <p className="whitespace-pre-wrap wrap-break-word">{comment.content}</p>
    <div className="flex flex-wrap gap-3 text-xs"><button className="font-bold" disabled={likePending} aria-pressed={comment.isLiked} onClick={() => void toggleLike()}>{comment.isLiked ? t('social.post.unlike') : t('social.post.like')} · {comment.likesCount}</button>{depth === 0 ? <button className="font-bold" onClick={() => setReplying((open) => !open)}>{t('social.comments.reply')}</button> : null}{canApproveComment(comment, postOwnerId, userId, parentIsHidden) ? <button className="font-bold" disabled={actions.approveComment.isPending && actions.approveComment.variables?.id === comment.id} onClick={() => void actions.approveComment.mutateAsync({ id: comment.id, postId }).catch(() => setError(true))}>{actions.approveComment.isPending && actions.approveComment.variables?.id === comment.id ? t('common.loading') : t('social.comments.approve')}</button> : null}{comment.userId === userId ? <button className="font-bold text-danger" onClick={() => setDeleteOpen(true)}>{t('social.comments.delete')}</button> : null}</div>
    {replying ? <form className="flex gap-2" onSubmit={(event) => void submit(event)}><label className="sr-only" htmlFor={`reply-${comment.id}`}>{t('social.comments.placeholder')}</label><input id={`reply-${comment.id}`} className="min-w-0 flex-1 bg-surface p-2" value={reply} onChange={(event) => setReply(event.currentTarget.value)} required />{COMMENT_LIMIT - replyLength <= COMMENT_WARNING_THRESHOLD ? <span aria-live="polite" className="text-xs text-muted">{COMMENT_LIMIT - replyLength}/{COMMENT_LIMIT}</span> : null}<button className={buttonClass('primary', 'sm')} disabled={actions.createComment.isPending || replyLength > COMMENT_LIMIT || !reply.trim()}>{t('common.send')}</button></form> : null}
    {error ? <p role="alert" className="inline-flex bg-surface-mid px-2 py-1 text-[11px] font-bold text-danger">{t('social.post.actionError')}</p> : null}
    <Dialog open={deleteOpen} onClose={() => setDeleteOpen(false)} title={t('social.comments.delete')} actions={<><Button variant="secondary" onClick={() => setDeleteOpen(false)}>{t('common.cancel')}</Button><Button variant="danger" onClick={() => { setDeleteOpen(false); void actions.deleteComment.mutateAsync({ id: comment.id, postId }).catch(() => setError(true)); }}>{t('common.delete')}</Button></>}>{t('social.comments.confirmDelete')}</Dialog>
     {comment.replies?.map((item) => <CommentRow key={item.id} comment={item} postId={postId} userId={userId} postOwnerId={postOwnerId} parentIsHidden={comment.isHidden} depth={depth + 1} />)}
  </article>;
}

function PostDetailPage() {
  const { id = '' } = useParams(); const session = useSession(); const { t, path } = useI18n(catalogs); const userId = session.user?.id ?? '';
  const post = usePost(userId, id); const comments = useComments(userId, id); const actions = useSocialActions(userId); const [content, setContent] = useState(''); const [error, setError] = useState(false);
  const contentLength = commentGraphemeCount(content);
  const rows = comments.data?.pages.flatMap((page) => Array.isArray(page) ? page : page.comments) ?? [];
  function doSubmit() { if (!content.trim() || commentGraphemeCount(content) > COMMENT_LIMIT) return; setError(false); void actions.createComment.mutateAsync({ id, content: content.trim() }).then(() => setContent('')).catch(() => setError(true)); }
  function submit(event: FormEvent) { event.preventDefault(); doSubmit(); }
  return <main className="mx-auto grid max-w-3xl gap-5 px-4 py-6 text-ink">
    <Link className="font-bold text-brand" to={path('feed')}>← {t('common.back')}</Link>
    {post.isPending ? <div className="grid gap-3 [&>span]:h-14 [&>span]:animate-[shimmer_1000ms_linear_infinite_alternate] [&>span]:bg-surface-mid" aria-label={t('common.loading')}><span /></div> : post.isError || !post.data ? <section className="grid justify-items-center gap-3.5 border border-(--hairline) bg-surface p-8 text-center" role="alert"><p>{t('common.error')}</p><button className={buttonClass('secondary')} onClick={() => void post.refetch()}>{t('common.retry')}</button></section> : <PostCard post={post.data} />}
    {post.data ? <section className="grid gap-4"><h1 className="font-display text-2xl font-bold">{t('social.comments.title')}</h1>
      {userId ? <form className="border border-(--hairline) bg-surface p-4 grid gap-3" onSubmit={submit}><ComposerInput id="new-comment" label={t('social.comments.placeholder')} placeholder={t('social.comments.placeholder')} value={content} maxLength={COMMENT_LIMIT} onChange={(value) => setContent(value)} onSubmit={doSubmit} textareaProps={{ required: true }} />{COMMENT_LIMIT - contentLength <= COMMENT_WARNING_THRESHOLD ? <span aria-live="polite" className="text-xs text-muted justify-self-end">{COMMENT_LIMIT - contentLength}/{COMMENT_LIMIT}</span> : null}<button className={`${buttonClass('primary')} justify-self-end`} disabled={actions.createComment.isPending || contentLength > COMMENT_LIMIT || !content.trim()}>{actions.createComment.isPending ? t('common.loading') : t('common.send')}</button>{error ? <p role="alert">{t('social.post.actionError')}</p> : null}</form> : <Link className={`${buttonClass('secondary')} justify-self-start`} to={path('login')}>{t('social.loginPrompt')}</Link>}
      {comments.isPending ? <div className="grid gap-3 [&>span]:h-14 [&>span]:animate-[shimmer_1000ms_linear_infinite_alternate] [&>span]:bg-surface-mid" aria-label={t('common.loading')}><span /><span /></div> : comments.isError ? <section role="alert" className="grid justify-items-center gap-3.5 border border-(--hairline) bg-surface p-8 text-center"><p>{t('social.comments.error')}</p><button className={buttonClass('secondary')} onClick={() => void comments.refetch()}>{t('common.retry')}</button></section> : !rows.length ? <section className="border border-(--hairline) bg-surface p-8 text-center">{t('social.comments.empty')}</section> : rows.map((comment) => <CommentRow key={comment.id} comment={comment} postId={id} userId={userId} postOwnerId={post.data?.userId ?? ''} />)}
      {comments.hasNextPage ? <button className={`${buttonClass('secondary')} justify-self-center`} disabled={comments.isFetchingNextPage} onClick={() => void comments.fetchNextPage()}>{t('common.loadMore')}</button> : null}
    </section> : null}
  </main>;
}

export default function PostRoute() { return <RequireAuth><PostDetailPage /></RequireAuth>; }
