import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router';
import { useSession } from '../../core/session';
import {
  useAuthText,
  AuthButton,
  AuthFrame,
  AuthInput,
  AuthMessage,
  AuthPassword,
} from './auth-frame';
import { OAuthButtons } from './oauth-buttons';
import { safeLocalizedReturnTo } from '../../core/routes';
import { authApi } from './auth.api';
import { useSubmit } from './use-submit';

export default function LoginPage() {
  const { t, path, locale } = useAuthText();
  const location = useLocation();
  const session = useSession();
  const navigate = useNavigate();
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const returnTo = safeLocalizedReturnTo(
    new URLSearchParams(location.search).get('returnTo'),
    locale,
    path('feed'),
  );
  const { submit, pending, error } = useSubmit(async () => {
    // ponytail: backend LoginDTO field stays `email` but accepts a unique @username too.
    const result = await authApi.login(identifier, password);
    await session.reload();
    await navigate(
      result.user?.username
        ? returnTo
        : `${path('complete-profile')}?returnTo=${encodeURIComponent(returnTo)}`,
    );
  });
  return (
    <AuthFrame
      title={t('auth.login.title')}
      description={t('auth.login.description')}
      footer={
        <>
          {t('auth.register.title')}?{' '}
          <Link className="font-bold text-brand underline" to={path('register')}>
            {t('auth.register.submit')}
          </Link>
        </>
      }
    >
      <form className="grid gap-5" onSubmit={submit}>
        <AuthInput
          label={t('auth.identifier')}
          name="identifier"
          type="text"
          inputMode="email"
          autoComplete="username"
          required
          minLength={3}
          maxLength={254}
          placeholder={t('auth.placeholder.identifier')}
          icon="user"
          value={identifier}
          onChange={(event) => setIdentifier(event.currentTarget.value)}
        />
        <AuthPassword
          label={t('auth.password')}
          name="password"
          autoComplete="current-password"
          required
          minLength={8}
          maxLength={100}
          placeholder={t('auth.placeholder.password')}
          value={password}
          onChange={(event) => setPassword(event.currentTarget.value)}
        />
        <div className="text-right">
          <Link className="text-sm font-semibold text-brand underline" to={path('forgot-password')}>
            {t('auth.password.recovery')}
          </Link>
        </div>
        <AuthButton type="submit" disabled={pending}>
          {pending ? t('common.loading') : t('auth.login.submit')}
        </AuthButton>
      </form>
      {error ? <AuthMessage error>{t('auth.error')}</AuthMessage> : null}
      <OAuthButtons returnTo={returnTo} />
    </AuthFrame>
  );
}
