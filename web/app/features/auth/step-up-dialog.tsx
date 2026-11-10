import { useCallback, useRef, useState, type FormEvent } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { Dialog, Input } from '../../components';
import { useSession } from '../../core/session';
import { useLatest } from '../../core/use-latest';
import { useAuthText, AuthButton, AuthMessage } from './auth-frame';
import { requestAppleCredential, requestGoogleCredential } from './oauth-buttons';
import { authApi } from './auth.api';

export type StepUpAction =
  | 'biometric_enroll'
  | 'delete_account'
  | 'export_data'
  | 'connect_dashboard'
  | 'cancel_order';
type CachedProof = { token: string; expiresAt: string };
export const stepUpProofKey = (userId: string, action: StepUpAction, resourceId?: string) =>
  ['user', userId, 'step-up', action, resourceId ?? null] as const;

export function StepUpDialog({
  open,
  onClose,
  action,
  resourceId,
  onVerified,
}: {
  open: boolean;
  onClose: () => void;
  action: StepUpAction;
  resourceId?: string;
  onVerified: (token: string) => void;
}) {
  const { t, locale } = useAuthText();
  const { user } = useSession();
  const queryClient = useQueryClient();
  const [password, setPassword] = useState('');
  const [pending, setPending] = useState(false);
  const [error, setError] = useState(false);
  const [emailSent, setEmailSent] = useState(false);
  const operation = useRef(0);
  const abortController = useRef<AbortController | null>(null);
  const googleTarget = useRef<HTMLDivElement>(null);
  // Latest callbacks via ref: the mount callback stays stable so the dialog does not
  // re-run its cache check (and reset the form) on every parent render.
  const actions = useLatest({ onClose, onVerified });

  const mountRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (!node) return;
      abortController.current?.abort();
      abortController.current = open ? new AbortController() : null;
      operation.current++;
      setPassword('');
      setError(false);
      setEmailSent(false);
      setPending(false);
      if (!open || !user) return;
      const key = stepUpProofKey(user.id, action, resourceId);
      const cached = queryClient.getQueryData<CachedProof>(key);
      if (cached && Date.parse(cached.expiresAt) > Date.now()) {
        queryClient.removeQueries({ queryKey: key, exact: true });
        actions.current.onVerified(cached.token);
        actions.current.onClose();
      } else if (cached) queryClient.removeQueries({ queryKey: key, exact: true });
      return () => abortController.current?.abort();
    },
    [open, action, resourceId, queryClient, user, actions],
  );

  async function verify(proof: Record<string, unknown>) {
    if (!user) return;
    const currentOperation = operation.current;
    const signal = abortController.current?.signal;
    setPending(true);
    setError(false);
    try {
      const result = await authApi.stepUp(
        {
          purpose: action,
          ...(resourceId ? { resourceId } : {}),
          proof,
        },
        signal,
      );
      if (currentOperation !== operation.current) return;
      queryClient.setQueryData<CachedProof>(stepUpProofKey(user.id, action, resourceId), {
        token: result.stepUpToken,
        expiresAt: result.expiresAt,
      });
      setPassword('');
      onVerified(result.stepUpToken);
      onClose();
    } catch {
      if (currentOperation === operation.current) setError(true);
    } finally {
      if (currentOperation === operation.current) setPending(false);
    }
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    await verify({ kind: 'password', password });
  }

  async function provider(kind: 'google' | 'apple') {
    const currentOperation = operation.current;
    const signal = abortController.current?.signal;
    setPending(true);
    setError(false);
    try {
      const proof =
        kind === 'google'
          ? { kind, idToken: await requestGoogleCredential(googleTarget.current, signal) }
          : { kind, ...(await requestAppleCredential(signal)) };
      if (currentOperation === operation.current) await verify(proof);
    } catch {
      if (currentOperation === operation.current) {
        setError(true);
        setPending(false);
      }
    }
  }

  async function requestEmailProof() {
    const currentOperation = operation.current;
    const signal = abortController.current?.signal;
    setPending(true);
    setError(false);
    try {
      await authApi.requestStepUpMagicLink(
        {
          purpose: action,
          ...(resourceId ? { resourceId } : {}),
          locale,
          consent: true,
        },
        signal,
      );
      if (currentOperation === operation.current) setEmailSent(true);
    } catch {
      if (currentOperation === operation.current) setError(true);
    } finally {
      if (currentOperation === operation.current) setPending(false);
    }
  }

  return (
    <Dialog
      open={open}
      onClose={() => {
        operation.current++;
        abortController.current?.abort();
        setPassword('');
        setError(false);
        onClose();
      }}
      title={t('auth.stepup.title')}
    >
      <div ref={mountRef} className="sr-only" aria-hidden />
      <form className="mt-5 grid gap-4" onSubmit={submit}>
        <Input
          label={t('auth.stepup.password')}
          type="password"
          autoComplete="current-password"
          minLength={8}
          maxLength={100}
          value={password}
          onChange={(event) => setPassword(event.currentTarget.value)}
        />
        <AuthButton type="submit" disabled={pending || password.length < 8}>
          {pending ? t('common.loading') : t('auth.stepup.submit')}
        </AuthButton>
      </form>
      <div className="mt-3 grid gap-3">
        <AuthButton type="button" disabled={pending} onClick={() => void provider('google')}>
          {t('auth.google')}
        </AuthButton>
        <div ref={googleTarget} className="min-h-11" />
        <AuthButton type="button" disabled={pending} onClick={() => void provider('apple')}>
          {t('auth.apple')}
        </AuthButton>
        <AuthButton
          type="button"
          disabled={pending || emailSent}
          onClick={() => void requestEmailProof()}
        >
          {emailSent ? t('auth.stepup.emailSent') : t('auth.stepup.email')}
        </AuthButton>
      </div>
      {emailSent ? <AuthMessage>{t('auth.stepup.emailSent')}</AuthMessage> : null}
      {error ? <AuthMessage error>{t('auth.error')}</AuthMessage> : null}
    </Dialog>
  );
}
