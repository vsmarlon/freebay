import { useCallback, useEffect, useRef, useState } from 'react';
import { api } from '../../core/api';
import { Frame, Panel, PersonCard, useAccountText, type User } from './account';
export default function CloseFriendsPage() {
  const { t } = useAccountText();
  const [q, setQ] = useState('');
  const [people, setPeople] = useState<User[]>([]);
  const [selected, setSelected] = useState<User[]>([]);
  const [error, setError] = useState(false);
  const [pending, setPending] = useState(false);
  async function load() {
    setPending(true);
    setError(false);
    try {
      const [list, candidates] = await Promise.all([
        api.get<{ users?: User[] } | User[]>('/users/me/close-friends?limit=50&offset=0'),
        api.get<{ users?: User[] } | User[]>(
          `/users/me/close-friends/candidates?q=${encodeURIComponent(q)}&limit=50&offset=0`,
        ),
      ]);
      setSelected(Array.isArray(list) ? list : (list.users ?? []));
      setPeople(Array.isArray(candidates) ? candidates : (candidates.users ?? []));
    } catch {
      setError(true);
    } finally {
      setPending(false);
    }
  }
  const loadRef = useRef(load);
  useEffect(() => {
    loadRef.current = load;
  });
  const mountRef = useCallback((node: HTMLDivElement | null) => {
    if (node) void loadRef.current();
  }, []);
  async function change(person: User, add: boolean) {
    try {
      await (add
        ? api.post(`/users/me/close-friends/${person.id}`)
        : api.patch(`/users/me/close-friends/${person.id}/remove`));
      await load();
    } catch {
      setError(true);
    }
  }
  return (
    <Frame title={t('closeFriends')}>
      <Panel>
        <div ref={mountRef} className="sr-only" aria-hidden />
        <form
          className="mb-4 flex gap-2"
          onSubmit={(e) => {
            e.preventDefault();
            void load();
          }}
        >
          <label className="sr-only" htmlFor="candidate-search">
            {t('searchHint')}
          </label>
          <input
            id="candidate-search"
            className="min-h-12 flex-1 bg-surface-high px-3"
            value={q}
            onChange={(e) => setQ(e.currentTarget.value)}
          />
          <button className="min-h-12 bg-brand px-4 text-on-brand">{t('search')}</button>
        </form>
        {error ? (
          <p role="alert" className="text-danger">
            {t('error')} <button onClick={() => void load()}>{t('retry')}</button>
          </p>
        ) : null}
        {pending ? <p role="status">{t('loading')}</p> : null}
        <h2 className="mb-2 font-bold">{t('closeFriends')}</h2>
        <div className="grid gap-2">
          {selected.map((u) => (
            <PersonCard
              key={u.id}
              user={u}
              action={
                <button
                  className="min-h-11 bg-surface-high px-3"
                  onClick={() => void change(u, false)}
                >
                  {t('remove')}
                </button>
              }
            />
          ))}
        </div>
        <h2 className="mb-2 mt-6 font-bold">{t('people')}</h2>
        <div className="grid gap-2">
          {people
            .filter((u) => !selected.some((s) => s.id === u.id))
            .map((u) => (
              <PersonCard
                key={u.id}
                user={u}
                action={
                  <button
                    className="min-h-11 bg-brand px-3 text-on-brand"
                    onClick={() => void change(u, true)}
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
