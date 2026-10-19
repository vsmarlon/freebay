import { useState, type FormEvent } from 'react';
import { Link, useLocation, useNavigate } from 'react-router';
import { api } from '../../core/api';
import { useSession } from '../../core/session';
import { useAuthText, AuthButton, AuthFrame, AuthInput, AuthMessage } from './auth-frame';
import { OAuthButtons } from './oauth-buttons';
import { safeLocalizedReturnTo } from '../../core/routes';

export default function LoginPage() {
  const { t, path, locale } = useAuthText();
  const location = useLocation();
  const session = useSession();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [pending, setPending] = useState(false);
  const [error, setError] = useState(false);
  const returnTo = safeLocalizedReturnTo(new URLSearchParams(location.search).get('returnTo'), locale, path('feed'));
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError(false);
    try {
      const result = await api.post<{ user?: { username?: string | null } }>('/auth/web/login', { email, password }, { auth: false });
      await session.reload();
      await navigate(result.user?.username ? returnTo : `${path('complete-profile')}?returnTo=${encodeURIComponent(returnTo)}`);
    } catch {
      setError(true);
    } finally {
      setPending(false);
    }
  }
  return <AuthFrame title={t('auth.login.title')} description={t('auth.login.description')} footer={<>{t('auth.register.title')}? <Link className="font-bold text-brand underline" to={path('register')}>{t('auth.submit')}</Link></>}>
    <form className="grid gap-5" onSubmit={submit}>
      <AuthInput label={t('auth.email')} name="email" type="email" autoComplete="email" required maxLength={254} value={email} onChange={(event) => setEmail(event.currentTarget.value)} />
      <AuthInput label={t('auth.password')} name="password" type="password" autoComplete="current-password" required minLength={8} maxLength={100} value={password} onChange={(event) => setPassword(event.currentTarget.value)} />
      <div className="text-right"><Link className="text-sm font-semibold text-brand underline" to={path('forgot-password')}>{t('auth.password.recovery')}</Link></div>
      <AuthButton type="submit" disabled={pending}>{pending ? t('common.loading') : t('auth.login.submit')}</AuthButton>
    </form>
    {error ? <AuthMessage error>{t('auth.error')}</AuthMessage> : null}
    <OAuthButtons returnTo={returnTo} />
  </AuthFrame>;
}
