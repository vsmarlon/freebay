import { useState } from 'react';
import { Frame, Panel, PersonCard, useAccountText } from '../account';
import { useChangeCloseFriend, useCloseFriends } from './close-friends.queries';

export default function CloseFriendsPage() {
  const { t } = useAccountText();
  const [input, setInput] = useState('');
  // The search only re-runs on submit, matching the old explicit-load behavior.
  const [query, setQuery] = useState('');
  const closeFriends = useCloseFriends(query);
  const change = useChangeCloseFriend();
  const selected = closeFriends.data?.selected ?? [];
  const candidates = closeFriends.data?.candidates ?? [];
  const pendingId = change.isPending ? change.variables?.userId : undefined;

  return (
    <Frame title={t('closeFriends')}>
      <Panel>
        <form
          className="mb-4 flex gap-2"
          onSubmit={(event) => {
            event.preventDefault();
            setQuery(input);
          }}
        >
          <label className="sr-only" htmlFor="candidate-search">
            {t('searchHint')}
          </label>
          <input
            id="candidate-search"
            className="min-h-12 flex-1 bg-surface-high px-3"
            value={input}
            onChange={(event) => setInput(event.currentTarget.value)}
          />
          <button className="min-h-12 bg-brand px-4 text-on-brand">{t('search')}</button>
        </form>
        {closeFriends.isError || change.isError ? (
          <p role="alert" className="text-danger">
            {t('error')} <button onClick={() => void closeFriends.refetch()}>{t('retry')}</button>
          </p>
        ) : null}
        {closeFriends.isFetching ? <p role="status">{t('loading')}</p> : null}
        <h2 className="mb-2 font-bold">{t('closeFriends')}</h2>
        <div className="grid gap-2">
          {selected.map((user) => (
            <PersonCard
              key={user.id}
              user={user}
              action={
                <button
                  className="min-h-11 bg-surface-high px-3"
                  disabled={pendingId === user.id}
                  onClick={() => change.mutate({ userId: user.id, add: false })}
                >
                  {t('remove')}
                </button>
              }
            />
          ))}
        </div>
        <h2 className="mb-2 mt-6 font-bold">{t('people')}</h2>
        <div className="grid gap-2">
          {candidates
            .filter((user) => !selected.some((friend) => friend.id === user.id))
            .map((user) => (
              <PersonCard
                key={user.id}
                user={user}
                action={
                  <button
                    className="min-h-11 bg-brand px-3 text-on-brand"
                    disabled={pendingId === user.id}
                    onClick={() => change.mutate({ userId: user.id, add: true })}
                  >
                    {t('save')}
                  </button>
                }
              />
            ))}
        </div>
      </Panel>
    </Frame>
  );
}
