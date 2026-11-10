import { useLocation } from 'react-router';
import { Frame, Panel, PersonCard, useAccountText } from '../account';
import { useRemoveSafety, useSafetyList } from './safety.queries';

export default function SafetyListPage() {
  const { t } = useAccountText();
  const restricted = useLocation().pathname.endsWith('/restricted');
  const endpoint = restricted ? '/users/me/restricted' : '/users/blocked';
  const list = useSafetyList(endpoint);
  const remove = useRemoveSafety(endpoint, restricted);
  const users = list.data ?? [];

  return (
    <Frame title={restricted ? t('restricted') : t('blocked')}>
      <Panel>
        {list.isError ? (
          <p role="alert" className="text-danger">
            {t('error')} <button onClick={() => void list.refetch()}>{t('retry')}</button>
          </p>
        ) : null}
        {remove.isError ? (
          <p role="alert" className="text-danger">
            {t('error')}
          </p>
        ) : null}
        {users.length ? (
          <div className="grid gap-2">
            {users.map((user) => (
              <PersonCard
                key={user.id}
                user={user}
                action={
                  <button
                    className="min-h-11 bg-surface-high px-3"
                    disabled={remove.isPending && remove.variables === user.id}
                    onClick={() => remove.mutate(user.id)}
                  >
                    {t('remove')}
                  </button>
                }
              />
            ))}
          </div>
        ) : !list.isError && !list.isPending ? (
          <p>{t('empty')}</p>
        ) : null}
      </Panel>
    </Frame>
  );
}
