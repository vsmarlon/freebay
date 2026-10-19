import { useEffect, useState, type FormEvent } from 'react';
import type { MetaFunction } from 'react-router';
import { useLocation, useNavigate } from 'react-router';
import { Link } from 'react-router';
import { api } from '../../core/api';
import { useSession } from '../../core/session';
import { useAuthText, AuthButton, AuthFrame, AuthMessage } from './auth-frame';

export const meta: MetaFunction = () => [{ name: 'referrer', content: 'no-referrer' }];

export default function VerifyEmailPage() {
  const { t, path } = useAuthText();
  const location = useLocation();
  const navigate = useNavigate();
  const session = useSession();
  const [token] = useState(() => new URLSearchParams(location.search).get('token') ?? '');
  const [pending, setPending] = useState(false);
  const [complete, setComplete] = useState(false);
  const [error, setError] = useState(false);
  useEffect(() => {
    if (location.search) window.history.replaceState({}, document.title, location.pathname);
  }, [location.pathname, location.search]);
  async function confirm(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!token || pending) return;
    setPending(true);
    setError(false);
    try {
      const result = await api.post<{ user?: { username?: string | null } }>('/auth/web/magic-link/consume', { token }, { auth: false });
      setComplete(true);
      await session.reload();
      await navigate(path(result.user?.username ? 'feed' : 'complete-profile'));
    } catch {
      setError(true);
    } finally {
      setPending(false);
    }
  }
  return <AuthFrame title={t('auth.magic.confirmTitle')} description={t('auth.magic.confirmNote')} footer={error ? <Link className="font-bold text-brand underline" to={path('register')}>{t('auth.magic.resend')}</Link> : undefined}>
    {token ? <form onSubmit={confirm}><AuthButton type="submit" disabled={pending || complete}>{pending ? t('common.loading') : t('auth.magic.confirm')}</AuthButton></form> : <AuthMessage error>{t('auth.magic.invalid')}</AuthMessage>}
    {complete ? <AuthMessage>{t('auth.magic.done')}</AuthMessage> : null}
    {error ? <AuthMessage error>{t('auth.magic.invalid')}</AuthMessage> : null}
  </AuthFrame>;
}
