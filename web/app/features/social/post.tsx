import { useState, type FormEvent } from 'react';
import { Link, useParams } from 'react-router';
import { useQueryClient } from '@tanstack/react-query';
import { useSession, RequireAuth } from '../../core/session';
import { useI18n } from '../../core/locale';
import { pathsFor } from '../../core/routes';
import { socialApi } from './data';
import { socialKeys, useComments, usePost, useSocialActions } from './queries';
import { PostCard } from './post-card';
import { canApproveComment, type Comment } from './types';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';

const catalogs = { en, 'pt-BR': ptBR };

function CommentRow({ comment, postId, userId, postOwnerId, parentIsHidden = false, depth = 0 }: { comment: Comment; postId: string; userId: string; postOwnerId: string; parentIsHidden?: boolean; depth?: number }) {
  const { t, path, locale } = useI18n(catalogs); const actions = useSocialActions(userId); const client = useQueryClient(); const [reply, setReply] = useState(''); const [replying, setReplying] = useState(false); const [error, setError] = useState(false);
  async function submit(event: FormEvent) { event.preventDefault(); setError(false); try { await actions.createComment.mutateAsync({ id: postId, content: reply.trim(), parentId: comment.id }); setReply(''); setReplying(false); } catch { setError(true); } }
  return <article className={`grid gap-2 bg-surface-mid p-3 ${depth ? 'ml-4 sm:ml-8' : ''}`}>
    <header className="flex items-center gap-2 text-sm"><Link className="font-bold" to={path(pathsFor.person(comment.userId))}>{comment.user?.displayName ?? t('social.post.anonymous')}</Link><time className="text-xs text-muted" dateTime={comment.createdAt}>{new Intl.DateTimeFormat(locale, { dateStyle: 'medium' }).format(new Date(comment.createdAt))}</time></header>
    <p className="whitespace-pre-wrap break-words">{comment.content}</p>
    <div className="flex flex-wrap gap-3 text-xs"><button className="font-bold" aria-pressed={comment.isLiked} onClick={async () => { try { await socialApi.likeComment(comment.id, comment.isLiked); await client.invalidateQueries({ queryKey: socialKeys(userId).comments(postId) }); } catch { setError(true); } }}>{comment.isLiked ? t('social.post.unlike') : t('social.post.like')} · {comment.likesCount}</button>{depth === 0 ? <button className="font-bold" onClick={() => setReplying((open) => !open)}>{t('social.comments.reply')}</button> : null}{canApproveComment(comment, postOwnerId, userId, parentIsHidden) ? <button className="font-bold" disabled={actions.approveComment.isPending && actions.approveComment.variables?.id === comment.id} onClick={() => void actions.approveComment.mutateAsync({ id: comment.id, postId }).catch(() => setError(true))}>{actions.approveComment.isPending && actions.approveComment.variables?.id === comment.id ? t('common.loading') : t('social.comments.approve')}</button> : null}{comment.userId === userId ? <button className="font-bold status-error" onClick={() => void actions.deleteComment.mutateAsync({ id: comment.id, postId }).catch(() => setError(true))}>{t('social.comments.delete')}</button> : null}</div>
    {replying ? <form className="flex gap-2" onSubmit={(event) => void submit(event)}><label className="sr-only" htmlFor={`reply-${comment.id}`}>{t('social.comments.placeholder')}</label><input id={`reply-${comment.id}`} className="min-w-0 flex-1 bg-surface p-2" value={reply} maxLength={1000} onChange={(event) => setReply(event.currentTarget.value)} required /><button className="ui-button ui-sm ui-primary" disabled={actions.createComment.isPending}>{t('common.send')}</button></form> : null}
    {error ? <p role="alert" className="status status-error">{t('social.post.actionError')}</p> : null}
     {comment.replies?.map((item) => <CommentRow key={item.id} comment={item} postId={postId} userId={userId} postOwnerId={postOwnerId} parentIsHidden={comment.isHidden} depth={depth + 1} />)}
  </article>;
}

function PostDetailPage() {
  const { id = '' } = useParams(); const session = useSession(); const { t, path } = useI18n(catalogs); const userId = session.user?.id ?? '';
  const post = usePost(userId, id); const comments = useComments(userId, id); const actions = useSocialActions(userId); const [content, setContent] = useState(''); const [error, setError] = useState(false);
  const rows = comments.data?.pages.flatMap((page) => Array.isArray(page) ? page : page.comments) ?? [];
  async function submit(event: FormEvent) { event.preventDefault(); setError(false); try { await actions.createComment.mutateAsync({ id, content: content.trim() }); setContent(''); } catch { setError(true); } }
  return <main className="mx-auto grid max-w-3xl gap-5 px-4 py-6 text-ink">
    <Link className="font-bold text-brand" to={path('feed')}>← {t('common.back')}</Link>
    {post.isPending ? <div className="loading-list" aria-label={t('common.loading')}><span /></div> : post.isError || !post.data ? <section className="error-state" role="alert"><p>{t('common.error')}</p><button className="ui-button ui-secondary" onClick={() => void post.refetch()}>{t('common.retry')}</button></section> : <PostCard post={post.data} />}
    {post.data ? <section className="grid gap-4"><h1 className="font-display text-2xl font-bold">{t('social.comments.title')}</h1>
      {userId ? <form className="surface grid gap-3" onSubmit={(event) => void submit(event)}><label className="sr-only" htmlFor="new-comment">{t('social.comments.placeholder')}</label><textarea id="new-comment" className="min-h-20 bg-surface-mid p-3" maxLength={1000} value={content} onChange={(event) => setContent(event.currentTarget.value)} placeholder={t('social.comments.placeholder')} required /><button className="ui-button ui-primary justify-self-end" disabled={actions.createComment.isPending}>{actions.createComment.isPending ? t('common.loading') : t('common.send')}</button>{error ? <p role="alert">{t('social.post.actionError')}</p> : null}</form> : <Link className="ui-button ui-secondary justify-self-start" to={path('login')}>{t('social.loginPrompt')}</Link>}
      {comments.isPending ? <div className="loading-list" aria-label={t('common.loading')}><span /><span /></div> : comments.isError ? <section role="alert" className="error-state"><p>{t('social.comments.error')}</p><button className="ui-button ui-secondary" onClick={() => void comments.refetch()}>{t('common.retry')}</button></section> : !rows.length ? <section className="empty-state">{t('social.comments.empty')}</section> : rows.map((comment) => <CommentRow key={comment.id} comment={comment} postId={id} userId={userId} postOwnerId={post.data?.userId ?? ''} />)}
      {comments.hasNextPage ? <button className="ui-button ui-secondary justify-self-center" disabled={comments.isFetchingNextPage} onClick={() => void comments.fetchNextPage()}>{t('common.loadMore')}</button> : null}
    </section> : null}
  </main>;
}

export default function PostRoute() { return <RequireAuth><PostDetailPage /></RequireAuth>; }
