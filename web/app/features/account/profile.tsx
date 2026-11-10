import { useState, type FormEvent } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Link, useNavigate, useParams } from 'react-router';
import { accountApi } from './api';
import { useSession } from '../../core/session';
import { paths, pathsFor } from '../../core/routes';
import { Timeline } from '../social/timeline';
import { ProfileHighlights } from '../stories';
import { startConversation } from '../chat';
import { Frame, Panel, useAccountText } from './account';
import { Avatar, Button, Dialog, Icon } from '../../components';

type Stats = Partial<{
  followersCount: number;
  followingCount: number;
  postsCount: number;
  productsCount: number;
}>;
export default function ProfilePage() {
  const { id } = useParams();
  const { t, path } = useAccountText();
  const { user: viewer } = useSession();
  const navigate = useNavigate();
  const owner = !id;
  const viewerId = viewer?.id;
  const [kind, setKind] = useState<'all' | 'post' | 'repost' | 'product'>('all');
  const client = useQueryClient();
  const profileKey = ['account', 'profile', id ?? 'me'];
  const relationshipKey = ['account', 'relationship', id, viewerId];
  const profile = useQuery({
    queryKey: profileKey,
    queryFn: ({ signal }) => (owner ? accountApi.me(signal) : accountApi.user(id!, signal)),
    retry: false,
  });
  const statsQuery = useQuery({
    queryKey: [...profileKey, 'stats'],
    queryFn: ({ signal }) => (owner ? accountApi.stats(signal) : accountApi.totals(id!, signal)),
    retry: false,
  });
  const relationship = useQuery({
    queryKey: relationshipKey,
    enabled: !owner && Boolean(viewerId),
    queryFn: async ({ signal }) => {
      const [follow, block] = await Promise.all([
        accountApi.isFollowing(id!, signal),
        accountApi.isBlocked(id!, signal),
      ]);
      return { following: follow.isFollowing, blocked: block.isBlocked };
    },
    retry: false,
  });
  const user = profile.data;
  const stats = statsQuery.data;
  const error = profile.isError || statsQuery.isError;
  const following = relationship.data?.following ?? null;
  const blocked = relationship.data?.blocked ?? null;
  const [notice, setNotice] = useState('');
  const [reportOpen, setReportOpen] = useState(false);
  const [reportReason, setReportReason] = useState('OTHER');
  const [reportDescription, setReportDescription] = useState('');
  const [reportPending, setReportPending] = useState(false);
  const [blockOpen, setBlockOpen] = useState(false);
  async function toggleFollow() {
    if (!user || following === null) return;
    try {
      const result = following
        ? await accountApi.unfollow(user.id)
        : await accountApi.follow(user.id);
      client.setQueryData(relationshipKey, { following: !following, blocked });
      if (typeof result.followersCount === 'number')
        client.setQueryData([...profileKey, 'stats'], (current: Stats | undefined) => ({
          ...current,
          followersCount: result.followersCount,
        }));
    } catch {
      setNotice(t('error'));
    }
  }
  async function messageUser() {
    if (!user) return;
    try {
      const result = await startConversation(user.id);
      navigate(path(paths.conversation(result.conversationId)));
    } catch {
      setNotice(t('error'));
    }
  }
  async function blockUser() {
    if (!user) return;
    try {
      if (blocked) await accountApi.unblock(user.id);
      else await accountApi.block(user.id);
      client.setQueryData(relationshipKey, { following, blocked: !blocked });
    } catch {
      setNotice(t('error'));
    }
  }
  async function restrictUser() {
    if (!user) return;
    try {
      await accountApi.restrict(user.id);
      setNotice(t('saveOk'));
    } catch {
      setNotice(t('error'));
    }
  }
  async function reportUser(event: FormEvent) {
    event.preventDefault();
    if (!user) return;
    setReportPending(true);
    try {
      await accountApi.reportUser({
        targetId: user.id,
        reason: reportReason,
        ...(reportDescription.trim()
          ? { description: reportDescription.trim().slice(0, 1000) }
          : {}),
      });
      setNotice(t('sent'));
      setReportOpen(false);
      setReportDescription('');
    } catch {
      setNotice(t('error'));
    } finally {
      setReportPending(false);
    }
  }
  return (
    <Frame title={t('profile')} publicPage={Boolean(id)} bare>
      {error ? (
        <Panel>
          <p role="alert">{t('error')}</p>
          <button onClick={() => location.reload()}>{t('retry')}</button>
        </Panel>
      ) : !user ? (
        <p role="status">{t('loading')}</p>
      ) : (
        <div className="grid gap-[18px] [&>section+section]:border-t [&>section+section]:border-ink/20 [&>section+section]:pt-[18px]">
          <Panel>
            <div className="h-36 bg-linear-to-br from-[#660062] via-brand to-[#ff9dee] bg-cover bg-center sm:h-52">
              {user.bannerUrl ? (
                <img
                  className="size-full  object-cover"
                  src={user.bannerUrl}
                  alt=""
                  onError={(event) => {
                    event.currentTarget.style.display = 'none';
                  }}
                />
              ) : null}
            </div>
            <div className="flex flex-wrap items-end justify-between gap-4">
              <Avatar src={user.avatarUrl} name={user.displayName} size={96} />
              <div className="flex flex-wrap gap-2">
                {owner ? (
                  <Link
                    className="grid size-11 place-items-center bg-brand text-on-brand"
                    to={path(paths.editProfile)}
                    aria-label={t('edit')}
                    title={t('edit')}
                  >
                    <Icon name="pencil" size={18} />
                  </Link>
                ) : viewer ? (
                  <>
                    <button
                      disabled={following === null}
                      className="grid size-11 place-items-center bg-brand text-on-brand disabled:opacity-50"
                      onClick={() => void toggleFollow()}
                      aria-label={following ? t('following') : t('follow')}
                      title={following ? t('following') : t('follow')}
                    >
                      <Icon name={following ? 'unfollow' : 'follow'} size={18} />
                    </button>
                    <button
                      type="button"
                      className="grid size-11 place-items-center bg-surface-high"
                      onClick={() => void messageUser()}
                      aria-label={t('message')}
                      title={t('message')}
                    >
                      <Icon name="messages" size={18} />
                    </button>
                    <button
                      disabled={blocked === null}
                      className="grid size-11 place-items-center bg-surface-high disabled:opacity-50"
                      onClick={() => {
                        if (blocked) void blockUser();
                        else setBlockOpen(true);
                      }}
                      aria-label={blocked ? t('unblock') : t('block')}
                      title={blocked ? t('unblock') : t('block')}
                    >
                      <Icon name="lock" size={18} />
                    </button>
                    <button
                      className="grid size-11 place-items-center bg-surface-high"
                      onClick={() => void restrictUser()}
                      aria-label={t('restrict')}
                      title={t('restrict')}
                    >
                      <Icon name="eyeOff" size={18} />
                    </button>
                    <button
                      className="grid size-11 place-items-center bg-surface-high"
                      onClick={() => setReportOpen(true)}
                      aria-label={t('report')}
                      title={t('report')}
                    >
                      <Icon name="shield" size={18} />
                    </button>
                  </>
                ) : (
                  <>
                    <Link
                      className="min-h-11 bg-brand px-4 py-3 text-on-brand"
                      to={path(paths.login)}
                    >
                      {t('signInToAct')}
                    </Link>
                    <Link className="min-h-11 bg-surface-high px-4 py-3" to={path(paths.register)}>
                      {t('registerLabel')}
                    </Link>
                  </>
                )}
              </div>
            </div>
            <h2 className="mt-4 font-display text-2xl font-bold">{user.displayName}</h2>
            <p className="text-secondary">{user.username ? `@${user.username}` : ''}</p>
            <p className="mt-3">{user.bio}</p>
            <p className="mt-2 text-secondary">
              {[user.city, user.state].filter(Boolean).join(', ')}
            </p>
            <div className="mt-5 flex flex-wrap gap-5">
              <Link
                className="inline-flex items-center gap-1.5"
                to={path(`${owner ? 'profile' : pathsFor.person(user.id)}/followers`)}
                aria-label={`${stats?.followersCount ?? user.followersCount ?? 0} ${t('followers')}`}
                title={t('followers')}
              >
                <Icon name="user" size={16} />
                <b>{stats?.followersCount ?? user.followersCount ?? 0}</b>
              </Link>
              <Link
                className="inline-flex items-center gap-1.5"
                to={path(`${owner ? 'profile' : pathsFor.person(user.id)}/following`)}
                aria-label={`${stats?.followingCount ?? user.followingCount ?? 0} ${t('following')}`}
                title={t('following')}
              >
                <Icon name="follow" size={16} />
                <b>{stats?.followingCount ?? user.followingCount ?? 0}</b>
              </Link>
              <span
                className="inline-flex items-center gap-1.5"
                aria-label={`${user.postsCount ?? 0} ${t('posts')}`}
                title={t('posts')}
              >
                <Icon name="doc" size={16} />
                <b>{user.postsCount ?? 0}</b>
              </span>
              <span
                className="inline-flex items-center gap-1.5"
                aria-label={`${user.productsCount ?? 0} ${t('products')}`}
                title={t('products')}
              >
                <Icon name="box" size={16} />
                <b>{user.productsCount ?? 0}</b>
              </span>
            </div>
            {notice ? (
              <p role="status" className="mt-3">
                {notice}
              </p>
            ) : null}
          </Panel>
          <nav className="my-4 flex flex-wrap gap-3" aria-label={t('accountShortcuts')}>
            {owner ? (
              <>
                <Link className="min-h-11 bg-surface-high p-3 " to={path(paths.myPosts)}>
                  {t('myPosts')}
                </Link>
                <Link className="min-h-11 bg-surface-high p-3 " to={path(paths.liked)}>
                  {t('likedPosts')}
                </Link>
                <Link className="min-h-11 bg-surface-high p-3 " to={path(paths.myProducts)}>
                  {t('myListings')}
                </Link>
                <Link className="min-h-11 bg-surface-high p-3 " to={path(paths.myStories)}>
                  {t('myStories')}
                </Link>
                <Link className="min-h-11 bg-surface-high p-3 " to={path(paths.saved)}>
                  {t('saved')}
                </Link>
                <Link className="min-h-11 bg-surface-high p-3 " to={path(paths.favorites)}>
                  {t('favorites')}
                </Link>
                <Link className="min-h-11 bg-surface-high p-3 " to={path(paths.orders)}>
                  {t('purchases')}
                </Link>
                <Link className="min-h-11 bg-surface-high p-3 " to={path(paths.wallet)}>
                  {t('wallet')}
                </Link>
              </>
            ) : null}
            <Link className="min-h-11 bg-surface-high p-3 " to={path(paths.userReviews(user.id))}>
              {t('reviews')}
            </Link>
          </nav>
          <ProfileHighlights userId={user.id} />
          <nav className="my-4 flex flex-wrap gap-2" aria-label={t('profile')}>
            {[
              ['all', t('all')],
              ['post', t('posts')],
              ['repost', t('reposts')],
              ['product', t('products')],
            ].map(([value, label]) => (
              <button
                key={value}
                aria-pressed={kind === value}
                className="min-h-11 bg-surface-high px-3"
                onClick={() => setKind(value as typeof kind)}
              >
                {label}
              </button>
            ))}
          </nav>
          <Timeline userId={user.id} kind={kind} />
          {reportOpen ? (
            <div
              className="fixed inset-0 z-50 grid place-items-center bg-black/60 p-4"
              role="dialog"
              aria-modal="true"
              aria-labelledby="report-dialog-title"
            >
              <form
                className="grid w-full max-w-lg gap-4 bg-surface p-5 text-ink"
                onSubmit={(event) => void reportUser(event)}
              >
                <h2 id="report-dialog-title" className="font-display text-xl font-bold">
                  {t('report')}
                </h2>
                <label className="grid grid-cols-1 gap-1.5 text-xs">
                  {t('reportReason')}
                  <select
                    className="min-h-[42px] min-w-0 border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink"
                    value={reportReason}
                    onChange={(event) => setReportReason(event.currentTarget.value)}
                  >
                    {reportReasons.map((reason) => (
                      <option key={reason} value={reason}>
                        {t(`reason_${reason}`)}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="grid grid-cols-1 gap-1.5 text-xs">
                  {t('description')}
                  <textarea
                    className="min-h-24 border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink"
                    maxLength={1000}
                    value={reportDescription}
                    onChange={(event) => setReportDescription(event.currentTarget.value)}
                  />
                </label>
                <div className="flex justify-end gap-3">
                  <button
                    type="button"
                    className="min-h-11 bg-surface-high px-3"
                    onClick={() => setReportOpen(false)}
                  >
                    {t('cancel')}
                  </button>
                  <button className="min-h-11 bg-brand px-3 text-on-brand" disabled={reportPending}>
                    {reportPending ? t('loading') : t('send')}
                  </button>
                </div>
              </form>
            </div>
          ) : null}
          <Dialog
            open={blockOpen}
            onClose={() => setBlockOpen(false)}
            title={t('block')}
            actions={
              <>
                <Button variant="secondary" onClick={() => setBlockOpen(false)}>
                  {t('cancel')}
                </Button>
                <Button
                  variant="danger"
                  onClick={() => {
                    setBlockOpen(false);
                    void blockUser();
                  }}
                >
                  {t('block')}
                </Button>
              </>
            }
          >
            {t('blockedConfirm')}
          </Dialog>
        </div>
      )}
    </Frame>
  );
}

const reportReasons = [
  'SPAM',
  'FRAUD',
  'HARASSMENT',
  'FAKE_ACCOUNT',
  'IMPERSONATING',
  'NUDITY',
  'BLACKMAIL',
  'FALSE_ADVERTISING',
  'OTHER',
] as const;
