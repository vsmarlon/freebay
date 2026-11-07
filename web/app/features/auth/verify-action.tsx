import { useCallback, useMemo, useState } from 'react';
import { Navigate, useLocation, useNavigate } from 'react-router';
import { useQueryClient } from '@tanstack/react-query';
import { Button } from '../../components';
import { api } from '../../core/api';
import { paths } from '../../core/routes';
import { useSession } from '../../core/session';
import { AuthFrame, AuthMessage, useAuthText } from './auth-frame';
import { stepUpProofKey, type StepUpAction } from './step-up-dialog';

const purposes: StepUpAction[] = ['biometric_enroll', 'delete_account', 'export_data', 'connect_dashboard', 'cancel_order'];

export default function VerifyActionPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, isPending, error: sessionError, reload } = useSession();
  const queryClient = useQueryClient();
  const { locale, t, path } = useAuthText();
  const params = useMemo(() => new URLSearchParams(location.search), []);
  const [token] = useState(() => params.get('token') ?? '');
  const [contextSignature] = useState(() => params.get('contextSignature') ?? '');
  const [purpose] = useState(() => params.get('purpose') ?? '');
  const [resourceId] = useState(() => params.get('resourceId') ?? undefined);
  const [error, setError] = useState(false);
  const [pending, setPending] = useState(false);
  const [confirmed, setConfirmed] = useState(false);
  const action = purposes.find((candidate) => candidate === purpose);
  const validResource = action === 'cancel_order'
    ? typeof resourceId === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(resourceId)
    : resourceId === undefined;

  const layoutRef = useCallback((node: HTMLDivElement | null) => {
    if (!node) return;
    window.history.replaceState(window.history.state, '', `${location.pathname}`);
    let meta = document.querySelector<HTMLMetaElement>('meta[name="referrer"]');
    if (!meta) { meta = document.createElement('meta'); meta.name = 'referrer'; document.head.append(meta); }
    meta.content = 'no-referrer';
  }, [location.pathname]);

  async function confirm() {
    if (!user || !action || !validResource || !token.startsWith('stepup.') || !/^[0-9a-f]{64}$/.test(contextSignature)) return;
    setPending(true); setError(false);
    try {
      const result = await api.post<{ stepUpToken: string; expiresAt: string }>('/auth/web/step-up', {
        purpose: action, ...(resourceId ? { resourceId } : {}),
        proof: { kind: 'magic_link', token, contextSignature },
      });
      queryClient.setQueryData(stepUpProofKey(user.id, action, resourceId), { token: result.stepUpToken, expiresAt: result.expiresAt });
      setConfirmed(true);
    } catch { setError(true); }
    finally { setPending(false); }
  }

  const actionLabel = action ? t(`auth.stepup.action.${action}`) : '';
  const destination = action === 'cancel_order' && resourceId
    ? path(paths.order(resourceId))
    : action === 'connect_dashboard' ? path(paths.wallet) : path(paths.privacy);
  if (isPending) return <p role="status">{t('common.loading')}</p>;
  if (sessionError) return <AuthFrame title={t('auth.stepup.verifyTitle')} description={t('auth.stepup.verifyDescription')}><AuthMessage error>{t('auth.error')}</AuthMessage><Button onClick={() => void reload()}>{t('common.retry')}</Button></AuthFrame>;
  if (!user) return <Navigate to={`/${locale}/login?returnTo=${encodeURIComponent(location.pathname)}`} replace />;
  return <AuthFrame title={t('auth.stepup.verifyTitle')} description={t('auth.stepup.verifyDescription')}>
    <div ref={layoutRef} className="sr-only" aria-hidden />
    {action && validResource && token.startsWith('stepup.') && /^[0-9a-f]{64}$/.test(contextSignature)
      ? <p className="mb-4">{t('auth.stepup.verifyAction', { action: actionLabel })}{resourceId ? ` ${resourceId}` : ''}</p>
      : <AuthMessage error>{t('auth.stepup.invalid')}</AuthMessage>}
    {confirmed
      ? <Button className="w-full" onClick={() => navigate(destination, { replace: true })}>{t('auth.stepup.returnToAction')}</Button>
      : <Button className="w-full" disabled={pending || !action || !validResource || !token.startsWith('stepup.') || !/^[0-9a-f]{64}$/.test(contextSignature)} onClick={() => void confirm()}>
        {pending ? t('common.loading') : t('auth.stepup.confirmAction')}
      </Button>}
    {error ? <AuthMessage error>{t('auth.stepup.invalid')}</AuthMessage> : null}
    <p className="mt-4 text-sm text-muted">{locale === 'en' ? 'This confirms only the requested action; it does not perform it.' : 'Isso confirma apenas a ação solicitada; não a executa.'}</p>
  </AuthFrame>;
}
