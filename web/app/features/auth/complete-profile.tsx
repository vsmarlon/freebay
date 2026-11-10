import { useCallback, useState } from 'react';
import { useLocation, useNavigate } from 'react-router';
import { useSession } from '../../core/session';
import { useAuthText, AuthButton, AuthFrame, AuthInput, AuthMessage } from './auth-frame';
import { safeLocalizedReturnTo } from '../../core/routes';
import { authApi } from './auth.api';
import { useSubmit } from './use-submit';

export default function CompleteProfilePage() {
  const { t, path, locale } = useAuthText();
  const location = useLocation();
  const session = useSession();
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [usernameCheck, setUsernameCheck] = useState<{
    available: boolean;
    suggestions: string[];
  } | null>(null);
  const returnTo = safeLocalizedReturnTo(
    new URLSearchParams(location.search).get('returnTo'),
    locale,
    path('feed'),
  );
  const checkRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (!node) return;
      setUsernameCheck(null);
      if (!/^[A-Za-z0-9_]{3,20}$/.test(username)) return;
      let active = true;
      const timer = window.setTimeout(() => {
        void authApi
          .usernameAvailable(username)
          .then((result) => {
            if (active) setUsernameCheck(result);
          })
          .catch(() => {
            if (active) setUsernameCheck(null);
          });
      }, 300);
      return () => {
        active = false;
        window.clearTimeout(timer);
      };
    },
    [username],
  );
  const { submit, pending, error } = useSubmit(async () => {
    await authApi.completeProfile({
      username,
      ...(displayName ? { displayName } : {}),
      ...(city ? { city } : {}),
      ...(state ? { state } : {}),
    });
    await session.reload();
    await navigate(returnTo);
  });
  return (
    <AuthFrame title={t('auth.profile.title')} description={t('auth.login.description')}>
      <div ref={checkRef} className="sr-only" aria-hidden />
      <form className="grid gap-5" onSubmit={submit}>
        <AuthInput
          label={t('auth.username')}
          required
          minLength={3}
          maxLength={20}
          pattern="[A-Za-z0-9_]{3,20}"
          autoComplete="username"
          value={username}
          onChange={(event) => setUsername(event.currentTarget.value)}
        />
        {usernameCheck ? (
          <p role="status" className="text-sm text-muted">
            {usernameCheck.available
              ? t('auth.username.available')
              : t('auth.username.unavailable')}
            {usernameCheck.suggestions.length
              ? ` ${t('auth.username.suggestions')}: ${usernameCheck.suggestions.join(', ')}`
              : ''}
          </p>
        ) : null}
        <AuthInput
          label={t('auth.displayName')}
          minLength={2}
          maxLength={50}
          autoComplete="name"
          value={displayName}
          onChange={(event) => setDisplayName(event.currentTarget.value)}
        />
        <div className="grid grid-cols-2 gap-3">
          <AuthInput
            label={t('auth.city')}
            maxLength={100}
            autoComplete="address-level2"
            value={city}
            onChange={(event) => setCity(event.currentTarget.value)}
          />
          <AuthInput
            label={t('auth.state')}
            maxLength={2}
            autoComplete="address-level1"
            value={state}
            onChange={(event) => setState(event.currentTarget.value)}
          />
        </div>
        <AuthButton type="submit" disabled={pending}>
          {pending ? t('common.loading') : t('auth.profile.submit')}
        </AuthButton>
      </form>
      {error ? <AuthMessage error>{t('auth.error')}</AuthMessage> : null}
    </AuthFrame>
  );
}
