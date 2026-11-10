import { useLocation, useParams } from 'react-router';
import { useSession } from '../../../core/session';
import { Frame, Panel, PersonCard, useAccountText, type User } from '../account';
import { useConnections, useFollowStates, useToggleFollow } from './connections.queries';

export default function ConnectionsPage() {
  const { id } = useParams();
  const location = useLocation();
  const { t } = useAccountText();
  const { user: currentUser } = useSession();
  const following = location.pathname.endsWith('/following');
  const kind = following ? 'following' : 'followers';
  const endpoint = id ? `/users/${encodeURIComponent(id)}/${kind}` : `/users/me/${kind}`;

  const connections = useConnections(endpoint);
  const toggleFollow = useToggleFollow(endpoint);
  const users = connections.data?.pages.flat() ?? [];
  // The owner's own following list is known-followed by definition; every other
  // list needs a per-person lookup, which is what the follow-states query is.
  const ownFollowingList = following && !id;
  const ids = ownFollowingList
    ? []
    : users.filter((person) => person.id !== currentUser?.id).map((person) => person.id);
  const states = useFollowStates(endpoint, ids, !ownFollowingList);
  const stateFor = (person: User) => (ownFollowingList ? true : states.data?.[person.id]);

  return (
    <Frame title={t(kind)}>
      <Panel>
        {connections.isError ? (
          <p role="alert" className="text-danger">
            {t('error')} <button onClick={() => void connections.refetch()}>{t('retry')}</button>
          </p>
        ) : null}
        {toggleFollow.isError ? (
          <p role="alert" className="text-danger">
            {t('error')}
          </p>
        ) : null}
        {users.length ? (
          <div className="grid gap-2">
            {users.map((person) => {
              const followed = stateFor(person);
              const pending =
                toggleFollow.isPending && toggleFollow.variables?.userId === person.id;
              return (
                <PersonCard
                  key={person.id}
                  user={person}
                  action={
                    person.id === currentUser?.id ? (
                      <span>{t('you')}</span>
                    ) : (
                      <button
                        type="button"
                        disabled={
                          toggleFollow.isPending || followed === undefined || followed === null
                        }
                        className="min-h-11 bg-surface-high px-3"
                        onClick={() =>
                          toggleFollow.mutate({
                            userId: person.id,
                            following: followed === true,
                            removeFromList: ownFollowingList && followed === true,
                          })
                        }
                      >
                        {pending ? t('loading') : followed ? t('unfollow') : t('follow')}
                      </button>
                    )
                  }
                />
              );
            })}
          </div>
        ) : !connections.isError && !connections.isPending ? (
          <p>{t('empty')}</p>
        ) : null}
        {connections.hasNextPage && users.length ? (
          <button
            className="mt-4 min-h-11 bg-surface-high px-4"
            onClick={() => void connections.fetchNextPage()}
          >
            {t('loadMore')}
          </button>
        ) : null}
      </Panel>
    </Frame>
  );
}
