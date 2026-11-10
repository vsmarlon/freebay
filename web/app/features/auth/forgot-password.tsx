import { useState } from 'react';
import { Link } from 'react-router';
import { useAuthText, AuthButton, AuthFrame, AuthInput, AuthMessage } from './auth-frame';
import { authApi } from './auth.api';
import { useSubmit } from './use-submit';

export default function ForgotPasswordPage() {
  const { t, path, locale } = useAuthText();
  const [email, setEmail] = useState('');
  const [step, setStep] = useState<'request' | 'done'>('request');
  const { submit, pending, error } = useSubmit(async () => {
    if (step === 'request') {
      await authApi.requestPasswordReset(email, locale);
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
      {step === 'done' ? (
        <AuthMessage>{t('auth.recovery.sent')}</AuthMessage>
      ) : (
        <form className="grid gap-5" onSubmit={submit}>
          <AuthInput
            label={t('auth.email')}
            type="email"
            autoComplete="email"
            required
            maxLength={254}
            value={email}
            onChange={(event) => setEmail(event.currentTarget.value)}
          />
          <AuthButton type="submit" disabled={pending}>
            {pending ? t('common.loading') : t('auth.recovery.request')}
          </AuthButton>
        </form>
      )}
      {error ? <AuthMessage error>{t('auth.error')}</AuthMessage> : null}
    </AuthFrame>
  );
}
