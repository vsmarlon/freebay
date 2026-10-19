import { useEffect, useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router';
import { api } from '../../core/api';
import { useSession } from '../../core/session';
import { useAuthText, AuthButton, AuthFrame, AuthInput, AuthMessage } from './auth-frame';
import { OAuthButtons } from './oauth-buttons';

export default function RegisterPage() {
  const { t, locale, path } = useAuthText();
  const navigate = useNavigate();
  const session = useSession();
  const [email, setEmail] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [consent, setConsent] = useState(false);
  const [mode, setMode] = useState<'magic' | 'password'>('magic');
  const [usernameAvailable, setUsernameAvailable] = useState<boolean | null>(null);
  const [pending, setPending] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState(false);
  useEffect(() => {
    setUsernameAvailable(null);
    if (!/^[A-Za-z0-9_]{3,20}$/.test(username)) return;
    let active = true;
    const timer = window.setTimeout(() => {
      void api.get<{ available: boolean }>(`/auth/username-available?u=${encodeURIComponent(username)}`, { auth: false })
        .then((result) => { if (active) setUsernameAvailable(result.available); })
        .catch(() => { if (active) setUsernameAvailable(null); });
    }, 300);
    return () => { active = false; window.clearTimeout(timer); };
  }, [username]);
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError(false);
    try {
      if (mode === 'magic') {
        await api.post('/auth/web/magic-link/request', { email, consent, locale }, { auth: false });
        setSent(true);
      } else {
        await api.post('/auth/web/register', { displayName, username, email, password }, { auth: false });
        await session.reload();
        await navigate(path('feed'));
      }
    } catch {
      setError(true);
    } finally {
      setPending(false);
    }
  }
  return <AuthFrame title={t('auth.register.title')} description={t('auth.register.description')} footer={<>{t('auth.login.title')}? <Link className="font-bold text-brand underline" to={path('login')}>{t('auth.login.submit')}</Link></>}>
    <form className="grid gap-5" onSubmit={submit}>
      {mode === 'password' ? <>
        <AuthInput label={t('auth.displayName')} name="displayName" autoComplete="name" required minLength={2} maxLength={50} value={displayName} onChange={(event) => setDisplayName(event.currentTarget.value)} />
        <AuthInput label={t('auth.username')} name="username" autoComplete="username" required minLength={3} maxLength={20} pattern="[A-Za-z0-9_]{3,20}" value={username} onChange={(event) => setUsername(event.currentTarget.value)} />
        {usernameAvailable !== null ? <p role="status" className="text-sm text-muted">{t(usernameAvailable ? 'auth.username.available' : 'auth.username.unavailable')}</p> : null}
        <AuthInput label={t('auth.email')} name="email" type="email" autoComplete="email" required maxLength={254} value={email} onChange={(event) => setEmail(event.currentTarget.value)} />
        <AuthInput label={t('auth.password')} name="password" type="password" autoComplete="new-password" required minLength={8} maxLength={100} value={password} onChange={(event) => setPassword(event.currentTarget.value)} />
      </> : <>
        <AuthInput label={t('auth.email')} name="email" type="email" autoComplete="email" required maxLength={254} value={email} onChange={(event) => setEmail(event.currentTarget.value)} />
        <label className="flex items-start gap-3 text-sm leading-6"><input className="mt-1 size-5 accent-[var(--brand)]" type="checkbox" required checked={consent} onChange={(event) => setConsent(event.currentTarget.checked)} /><span>{t('auth.consent')}</span></label>
      </>}
      <AuthButton type="submit" disabled={pending}>{pending ? t('common.loading') : t('auth.submit')}</AuthButton>
    </form>
    <button type="button" className="mt-4 text-sm font-semibold text-brand underline" onClick={() => setMode(mode === 'magic' ? 'password' : 'magic')}>{t(mode === 'magic' ? 'auth.register.passwordMode' : 'auth.register.magicMode')}</button>
    {sent ? <AuthMessage>{t('auth.magic.sent')}</AuthMessage> : null}
    {error ? <AuthMessage error>{t('auth.error')}</AuthMessage> : null}
    <OAuthButtons />
  </AuthFrame>;
}
