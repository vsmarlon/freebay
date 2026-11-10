import { useCallback, useState } from 'react';
import { Link, useLocation } from 'react-router';
import { useAuthText, AuthButton, AuthFrame, AuthInput, AuthMessage } from './auth-frame';
import { authApi } from './auth.api';
import { useSubmit } from './use-submit';

export function headers() {
  return { 'Cache-Control': 'no-store', 'Referrer-Policy': 'no-referrer' };
}

export default function ResetPasswordPage() {
  const { t, path } = useAuthText();
  const location = useLocation();
  const [email, setEmail] = useState(() => new URLSearchParams(location.search).get('email') ?? '');
  const [code, setCode] = useState(() => new URLSearchParams(location.search).get('token') ?? '');
  const [token, setToken] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [step, setStep] = useState<'verify' | 'reset' | 'done'>('verify');
  const mountRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (!node) return;
      const fragment = new URLSearchParams(window.location.hash.slice(1));
      const linkToken = fragment.get('token');
      const currentQuery = new URLSearchParams(location.search);
      const queryToken = currentQuery.get('token');
      if (linkToken) {
        setToken(linkToken);
        setStep('reset');
      } else if (queryToken && !currentQuery.get('email')) {
        setToken(queryToken);
        setStep('reset');
      }
      if (window.location.hash || location.search)
        window.history.replaceState({}, document.title, location.pathname);
    },
    [location.pathname, location.search],
  );
  const { submit, pending, error } = useSubmit(async () => {
    if (token) {
      if (newPassword !== confirmPassword) throw new Error('password mismatch');
      await authApi.consumePasswordReset(token, newPassword);
      setStep('done');
    } else if (step === 'verify') {
      await authApi.verifyResetCode(email, code);
      setStep('reset');
    } else {
      await authApi.resetPassword({ email, code, newPassword });
      setStep('done');
    }
  });
  return (
    <AuthFrame
      title={t('auth.recovery.title')}
      description={t('auth.login.description')}
      footer={
        <Link className="font-bold text-brand underline" to={path('login')}>
          {t('common.back')}
        </Link>
      }
    >
      <div ref={mountRef} className="sr-only" aria-hidden />
      <meta name="referrer" content="no-referrer" />
      {step === 'done' ? (
        <AuthMessage>{t('auth.recovery.done')}</AuthMessage>
      ) : (
        <form className="grid gap-5" onSubmit={submit}>
          {!token ? (
            <>
              <AuthInput
                label={t('auth.email')}
                type="email"
                autoComplete="email"
                required
                maxLength={254}
                value={email}
                onChange={(event) => setEmail(event.currentTarget.value)}
              />
              <AuthInput
                label={t('auth.recovery.code')}
                inputMode="numeric"
                autoComplete="one-time-code"
                required
                pattern="[0-9]{6}"
                minLength={6}
                maxLength={6}
                value={code}
                onChange={(event) => setCode(event.currentTarget.value)}
              />
            </>
          ) : null}
          {step === 'reset' ? (
            <>
              <AuthInput
                label={t('auth.recovery.newPassword')}
                type="password"
                autoComplete="new-password"
                required
                minLength={8}
                maxLength={100}
                value={newPassword}
                onChange={(event) => setNewPassword(event.currentTarget.value)}
              />
              {token ? (
                <AuthInput
                  label={t('auth.recovery.confirmPassword')}
                  type="password"
                  autoComplete="new-password"
                  required
                  minLength={8}
                  maxLength={100}
                  value={confirmPassword}
                  onChange={(event) => setConfirmPassword(event.currentTarget.value)}
                />
              ) : null}
            </>
          ) : null}
          <AuthButton type="submit" disabled={pending}>
            {pending
              ? t('common.loading')
              : t(step === 'verify' ? 'auth.recovery.verify' : 'auth.recovery.reset')}
          </AuthButton>
        </form>
      )}
      {error ? <AuthMessage error>{t('auth.error')}</AuthMessage> : null}
    </AuthFrame>
  );
}
