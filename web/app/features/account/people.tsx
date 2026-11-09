import { useState } from 'react';
import { api } from '../../core/api';
import { Frame, Panel, PersonCard, useAccountText, type User } from './account';
export default function PeoplePage() {
  const { t } = useAccountText();
  const [query, setQuery] = useState('');
  const [users, setUsers] = useState<User[]>([]);
  const [offset, setOffset] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState(false);
  async function search(next = false) {
    setPending(true);
    setError(false);
    const start = next ? offset : 0;
    try {
      const result = await api.get<{ users: User[]; hasMore: boolean; nextOffset: number | null }>(
        `/users/search?q=${encodeURIComponent(query.trim())}&limit=20&offset=${start}`,
      );
      setUsers((current) => (next ? [...current, ...result.users] : result.users));
      setOffset(result.nextOffset ?? start);
      setHasMore(result.hasMore);
    } catch {
      setError(true);
    } finally {
      setPending(false);
    }
  }
  return (
    <Frame title={t('people')}>
      <Panel>
        <form
          className="flex flex-wrap gap-3"
          onSubmit={(e) => {
            e.preventDefault();
            void search();
          }}
        >
          <label className="sr-only" htmlFor="people-search">
            {t('searchHint')}
          </label>
          <input
            id="people-search"
            className="min-h-12 min-w-0 flex-1 bg-surface-high px-3"
            value={query}
            onChange={(e) => setQuery(e.currentTarget.value)}
            placeholder={t('searchHint')}
            maxLength={100}
          />
          <button className="min-h-12 bg-brand px-5 text-on-brand" disabled={pending}>
            {pending ? t('loading') : t('search')}
          </button>
        </form>
        {error ? (
          <p role="alert" className="mt-4 text-danger">
            {t('error')}{' '}
            <button className="underline" onClick={() => void search()}>
              {t('retry')}
            </button>
          </p>
        ) : null}
        <div className="mt-4 grid gap-2">
          {users.map((user) => (
            <PersonCard key={user.id} user={user} />
          ))}
        </div>
        {!pending && !error && query && users.length === 0 ? (
          <p className="mt-4">{t('noResults')}</p>
        ) : null}
        {hasMore ? (
          <button
            className="mt-4 min-h-12 bg-surface-high px-4"
            disabled={pending}
            onClick={() => void search(true)}
          >
            {t('loadMore')}
          </button>
        ) : null}
      </Panel>
    </Frame>
  );
}
