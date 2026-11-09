import { useState, type FormEvent } from 'react';
import { accountApi } from './api';
import { Button, TextArea } from '../../components';
import { redactSensitiveDiagnostics } from './bug-report-sanitizer';
import { Frame, Panel, useAccountText } from './account';

export default function BugReportPage() {
  const { t } = useAccountText();
  const [description, setDescription] = useState('');
  const [logs, setLogs] = useState('');
  const [pending, setPending] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState(false);
  async function submit(event: FormEvent) {
    event.preventDefault();
    setPending(true);
    setError(false);
    setSent(false);
    const safeDescription = redactSensitiveDiagnostics(description.trim()).slice(0, 5000);
    const safeLogs = redactSensitiveDiagnostics(logs.trim()).slice(0, 5000);
    const reportText = [safeDescription, safeLogs ? `${t('diagnosticsLabel')}\n${safeLogs}` : '']
      .filter(Boolean)
      .join('\n\n')
      .slice(0, 5000);
    try {
      await accountApi.sendBugReport({
        description: reportText,
        appVersion: 'web',
        platform: navigator.userAgent.slice(0, 250),
        screenContext: location.pathname.slice(0, 200),
      });
      setSent(true);
      setDescription('');
      setLogs('');
    } catch {
      setError(true);
    } finally {
      setPending(false);
    }
  }
  return (
    <Frame title={t('bugReport')}>
      <Panel>
        <form className="grid gap-4" onSubmit={submit}>
          <TextArea
            label={t('description')}
            className="min-h-32"
            required
            minLength={1}
            maxLength={5000}
            value={description}
            onChange={(e) => setDescription(e.currentTarget.value)}
          />
          <TextArea
            label={t('diagnostics')}
            className="min-h-32 font-mono text-sm"
            maxLength={5000}
            value={logs}
            onChange={(e) => setLogs(e.currentTarget.value)}
          />
          <p className="text-sm text-secondary">{t('diagnosticsPrivacyNote')}</p>
          <p className="text-sm text-secondary">{t('browserDiagnosticsNote')}</p>
          <Button disabled={pending}>{pending ? t('loading') : t('send')}</Button>
          {sent ? <p role="status">{t('sent')}</p> : null}
          {error ? (
            <p role="alert" className="text-danger">
              {t('error')}
            </p>
          ) : null}
        </form>
      </Panel>
    </Frame>
  );
}
