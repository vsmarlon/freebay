import { useState, type FormEvent } from 'react';
import { Link } from 'react-router';
import { api } from '../../core/api';
import { useAuthText, AuthButton, AuthFrame, AuthInput, AuthMessage } from './auth-frame';

export default function ForgotPasswordPage() {
  const { t, path, locale } = useAuthText();
  const [email, setEmail] = useState('');
  const [step, setStep] = useState<'request' | 'done'>('request');
  const [pending, setPending] = useState(false);
  const [error, setError] = useState(false);
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError(false);
    try {
      if (step === 'request') {
        await api.post('/auth/web/password-reset/request', { email, locale }, { auth: false });
        setStep('done');
      }
    } catch {
      setError(true);
    } finally {
      setPending(false);
    }
  }
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
