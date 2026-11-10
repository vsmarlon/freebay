import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Link } from 'react-router';
import { accountApi } from './api';
import { paths } from '../../core/routes';
import { StepUpDialog } from '../auth';
import { Frame, Panel, useAccountText } from './account';
export default function PrivacyPage() {
  const { t, path } = useAccountText();
  const [action, setAction] = useState<'export_data' | 'delete_account' | null>(null);
  const [message, setMessage] = useState('');
  const [error, setError] = useState(false);
  const client = useQueryClient();
  const me = useQuery({
    queryKey: ['account', 'me'],
    queryFn: ({ signal }) => accountApi.me(signal),
    retry: false,
  });
  const deletionPending = Boolean(me.data?.deletionRequestedAt);
  async function verified(token: string) {
    const current = action;
    if (!current) return;
    setError(false);
    setMessage('');
    try {
      if (current === 'export_data') {
        const data = await accountApi.exportData(token);
        const url = URL.createObjectURL(
          new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' }),
        );
        const a = document.createElement('a');
        a.href = url;
        a.download = 'freebay-account-export.json';
        a.click();
        URL.revokeObjectURL(url);
        setMessage(t('exportScope'));
      } else {
        if (!window.confirm(t('deleteConfirm'))) return;
        const result = await accountApi.requestDeletion(token);
        setMessage(t('deletionScheduled', { date: result.purgeAfter }));
      }
    } catch {
      setError(true);
    }
  }
  async function cancelDeletion() {
    if (!window.confirm(t('cancelDeletionConfirm'))) return;
    setError(false);
    try {
      await accountApi.cancelDeletion();
      await client.invalidateQueries({ queryKey: ['account', 'me'] });
      setMessage(t('deletionCancelled'));
    } catch {
      setError(true);
    }
  }
  return (
    <Frame title={t('privacy')}>
      <Panel>
        <div className="grid gap-4">
          <Link to={path(paths.closeFriends)} className="underline">
            {t('closeFriends')}
          </Link>
          <Link to={path(paths.blocked)} className="underline">
            {t('safety')}
          </Link>
          <button
            className="min-h-12 bg-surface-high px-4 text-left"
            onClick={() => setAction('export_data')}
          >
            {t('export')}
          </button>
          {deletionPending ? (
            <>
              <p role="status">{t('deletionPending')}</p>
              <button
                className="min-h-12 bg-surface-high px-4 text-left"
                onClick={() => void cancelDeletion()}
              >
                {t('cancelDeletion')}
              </button>
              <Link className="underline" to={path('login')}>
                {t('freshLogin')}
              </Link>
            </>
          ) : null}
          <button
            className="min-h-12 bg-danger px-4 text-left text-white"
            onClick={() => setAction('delete_account')}
          >
            {t('delete')}
          </button>
          {message ? <p role="status">{message}</p> : null}
          {error ? (
            <p role="alert" className="text-danger">
              {t('privacyError')}
            </p>
          ) : null}
          <p className="text-sm text-secondary">{t('freshSession')}</p>
        </div>
      </Panel>
      <StepUpDialog
        open={action !== null}
        action={action ?? 'export_data'}
        onClose={() => setAction(null)}
        onVerified={(token) => void verified(token)}
      />
    </Frame>
  );
}
