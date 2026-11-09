import { useInfiniteQuery } from '@tanstack/react-query';
import { useState } from 'react';
import { accountApi } from './api';
import { Frame, Panel, PersonCard, useAccountText } from './account';

export default function PeoplePage() {
  const { t } = useAccountText();
  const [input, setInput] = useState('');
  const [query, setQuery] = useState('');
  const search = useInfiniteQuery({
    queryKey: ['account', 'people', query],
    enabled: query.length > 0,
    initialPageParam: 0,
    queryFn: ({ pageParam }) => accountApi.searchPeople(query, pageParam),
    getNextPageParam: (last) => (last.hasMore ? (last.nextOffset ?? undefined) : undefined),
    retry: false,
  });
  const users = search.data?.pages.flatMap((page) => page.users) ?? [];

  return (
    <Frame title={t('people')}>
      <Panel>
        <form
          className="flex flex-wrap gap-3"
          onSubmit={(event) => {
            event.preventDefault();
            setQuery(input);
          }}
        >
          <label className="sr-only" htmlFor="people-search">
            {t('searchHint')}
          </label>
          <input
            id="people-search"
            className="min-h-12 min-w-0 flex-1 bg-surface-high px-3"
            value={input}
            onChange={(event) => setInput(event.currentTarget.value)}
            placeholder={t('searchHint')}
            maxLength={100}
          />
          <button className="min-h-12 bg-brand px-5 text-on-brand" disabled={search.isFetching}>
            {search.isFetching ? t('loading') : t('search')}
          </button>
        </form>
        {search.isError ? (
          <p role="alert" className="mt-4 text-danger">
            {t('error')}{' '}
            <button className="underline" onClick={() => void search.refetch()}>
              {t('retry')}
            </button>
          </p>
        ) : null}
        <div className="mt-4 grid gap-2">
          {users.map((user) => (
            <PersonCard key={user.id} user={user} />
          ))}
        </div>
        {!search.isFetching && !search.isError && query && users.length === 0 ? (
          <p className="mt-4">{t('noResults')}</p>
        ) : null}
        {search.hasNextPage ? (
          <button
            className="mt-4 min-h-12 bg-surface-high px-4"
            disabled={search.isFetchingNextPage}
            onClick={() => void search.fetchNextPage()}
          >
            {t('loadMore')}
          </button>
        ) : null}
      </Panel>
    </Frame>
  );
}
