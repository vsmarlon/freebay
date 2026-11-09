import { useCallback, useRef, useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router';
import { useSession } from '../../core/session';
import {
  useAuthText,
  AuthButton,
  AuthFrame,
  AuthInput,
  AuthMessage,
  AuthPassword,
} from './auth-frame';
import { Checkbox } from '../../components';
import { OAuthButtons } from './oauth-buttons';
import { authApi } from './auth.api';

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
  const consentRef = useRef<HTMLInputElement>(null);
  const consentMountRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (node && consentRef.current?.checked && !consent) setConsent(true);
    },
    [consent],
  );
  const usernameCheckRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (!node) return;
      setUsernameAvailable(null);
      if (!/^[A-Za-z0-9_]{3,20}$/.test(username)) return;
      let active = true;
      const timer = window.setTimeout(() => {
        void authApi
          .usernameAvailable(username)
          .then((result) => {
            if (active) setUsernameAvailable(result.available);
          })
          .catch(() => {
            if (active) setUsernameAvailable(null);
          });
      }, 300);
      return () => {
        active = false;
        window.clearTimeout(timer);
      };
    },
    [username],
  );
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError(false);
    try {
      if (mode === 'magic') {
        await authApi.requestMagicLink({ email, consent, locale });
        setSent(true);
      } else {
        await authApi.register({ displayName, username, email, password });
        await session.reload();
        await navigate(path('feed'));
      }
    } catch {
      setError(true);
    } finally {
      setPending(false);
    }
  }
  return (
    <AuthFrame
      title={t('auth.register.title')}
      description={t('auth.register.description')}
      footer={
        <>
          {t('auth.login.title')}?{' '}
          <Link className="font-bold text-brand underline" to={path('login')}>
            {t('auth.login.submit')}
          </Link>
        </>
      }
    >
      <div ref={consentMountRef} className="sr-only" aria-hidden />
      <div ref={usernameCheckRef} className="sr-only" aria-hidden />
      <form className="grid gap-5" onSubmit={submit}>
        {mode === 'password' ? (
          <>
            <AuthInput
              label={t('auth.displayName')}
              name="displayName"
              autoComplete="name"
              required
              minLength={2}
              maxLength={50}
              placeholder={t('auth.placeholder.name')}
              icon="user"
              value={displayName}
              onChange={(event) => setDisplayName(event.currentTarget.value)}
            />
            <AuthInput
              label={t('auth.username')}
              name="username"
              autoComplete="username"
              required
              minLength={3}
              maxLength={20}
              pattern="[A-Za-z0-9_]{3,20}"
              placeholder={t('auth.placeholder.username')}
              icon="at"
              value={username}
              onChange={(event) => setUsername(event.currentTarget.value)}
            />
            {usernameAvailable !== null ? (
              <p role="status" className="text-sm text-muted">
                {t(usernameAvailable ? 'auth.username.available' : 'auth.username.unavailable')}
              </p>
            ) : null}
            <AuthInput
              label={t('auth.email')}
              name="email"
              type="email"
              autoComplete="email"
              required
              maxLength={254}
              placeholder={t('auth.placeholder.email')}
              icon="mail"
              value={email}
              onChange={(event) => setEmail(event.currentTarget.value)}
            />
            <AuthPassword
              label={t('auth.password')}
              name="password"
              autoComplete="new-password"
              required
              minLength={8}
              maxLength={100}
              placeholder={t('auth.placeholder.password')}
              value={password}
              onChange={(event) => setPassword(event.currentTarget.value)}
            />
          </>
        ) : (
          <>
            <AuthInput
              label={t('auth.email')}
              name="email"
              type="email"
              autoComplete="email"
              required
              maxLength={254}
              placeholder={t('auth.placeholder.email')}
              icon="mail"
              value={email}
              onChange={(event) => setEmail(event.currentTarget.value)}
            />
            <Checkbox
              label={t('auth.consent')}
              ref={consentRef}
              required
              checked={consent}
              onChange={(event) => setConsent(event.currentTarget.checked)}
            />
          </>
        )}
        <AuthButton type="submit" disabled={pending}>
          {pending ? t('common.loading') : t('auth.submit')}
        </AuthButton>
      </form>
      <button
        type="button"
        className="mt-4 text-sm font-semibold text-brand underline"
        onClick={() => setMode(mode === 'magic' ? 'password' : 'magic')}
      >
        {t(mode === 'magic' ? 'auth.register.passwordMode' : 'auth.register.magicMode')}
      </button>
      {sent ? <AuthMessage>{t('auth.magic.sent')}</AuthMessage> : null}
      {error ? <AuthMessage error>{t('auth.error')}</AuthMessage> : null}
      <OAuthButtons />
    </AuthFrame>
  );
}
