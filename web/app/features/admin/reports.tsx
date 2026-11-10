import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { Button, Empty, ErrorState, Loading, Status, Surface } from '../../components';
import { useI18n } from '../../core/locale';
import { adminApi } from './api';
import type { AdminReport, ReportStatus } from './types';

const FILTERS: Array<{ value: ReportStatus | 'ALL'; pt: string; en: string }> = [
  { value: 'PENDING', pt: 'Pendentes', en: 'Pending' },
  { value: 'RESOLVED', pt: 'Resolvidas', en: 'Resolved' },
  { value: 'REJECTED', pt: 'Rejeitadas', en: 'Rejected' },
  { value: 'REVIEWED', pt: 'Revisadas', en: 'Reviewed' },
  { value: 'ALL', pt: 'Todas', en: 'All' },
];

const tone = (status: ReportStatus) =>
  status === 'RESOLVED'
    ? 'success'
    : status === 'REJECTED'
      ? 'neutral'
      : status === 'PENDING'
        ? 'warning'
        : 'info';

const targetOf = (report: AdminReport) => {
  const id =
    report.reportedPostId ??
    report.reportedDirectConversationId ??
    report.reportedOrderChatId ??
    report.reportedDirectMessageId ??
    report.reportedChatMessageId ??
    report.reportedUser?.id;
  return id ? `${report.targetType} ${id.slice(0, 8)}` : report.targetType;
};

export default function AdminReportsPage() {
  const { locale } = useI18n();
  const pt = locale === 'pt-BR';
  const [filter, setFilter] = useState<ReportStatus | 'ALL'>('PENDING');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['admin', 'reports', filter],
    queryFn: ({ signal }) => adminApi.reports(filter === 'ALL' ? undefined : filter, signal),
  });

  const reports = query.data?.items ?? [];
  const selected = reports.find((report) => report.id === selectedId) ?? reports[0] ?? null;

  const resolve = useMutation({
    mutationFn: ({
      id,
      body,
    }: {
      id: string;
      body: { status: 'RESOLVED' | 'REJECTED'; note?: string };
    }) => adminApi.resolveReport(id, body),
    onSuccess: () => void queryClient.invalidateQueries({ queryKey: ['admin', 'reports'] }),
  });

  if (query.isPending) return <Loading label={pt ? 'Carregando denúncias…' : 'Loading reports…'} />;
  if (query.isError) return <ErrorState error={query.error} onRetry={() => void query.refetch()} />;

  return (
    <div className="grid gap-4">
      <div className="flex flex-wrap items-end gap-3">
        <label className="grid gap-1.5 text-xs">
          <span>{pt ? 'Filtrar por status' : 'Filter by status'}</span>
          <select
            className="min-h-[42px] border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink"
            value={filter}
            onChange={(event) => {
              setFilter(event.target.value as ReportStatus | 'ALL');
              setSelectedId(null);
            }}
          >
            {FILTERS.map((option) => (
              <option key={option.value} value={option.value}>
                {pt ? option.pt : option.en}
              </option>
            ))}
          </select>
        </label>
        <p className="m-0 text-sm text-muted">
          {pt ? `${reports.length} denúncia(s)` : `${reports.length} report(s)`}
        </p>
      </div>

      {reports.length === 0 ? (
        <Empty
          title={pt ? 'Fila vazia' : 'Queue empty'}
          description={pt ? 'Nenhuma denúncia neste status.' : 'No reports with this status.'}
        />
      ) : (
        <div className="grid gap-4 lg:grid-cols-[minmax(260px,380px)_minmax(0,1fr)]">
          <div className="grid content-start gap-2">
            {reports.map((report) => (
              <button
                key={report.id}
                type="button"
                onClick={() => setSelectedId(report.id)}
                className={`grid cursor-pointer gap-1.5 border p-3 text-left ${
                  selected?.id === report.id
                    ? 'border-brand bg-surface-high'
                    : 'border-(--hairline) bg-surface hover:bg-surface-mid'
                }`}
              >
                <strong className="truncate">{report.reason}</strong>
                <Status tone={tone(report.status)}>{report.status}</Status>
                <small className="text-muted">{targetOf(report)}</small>
                <small className="text-muted">
                  {new Date(report.createdAt).toLocaleString(locale)}
                </small>
                {report.description ? (
                  <span className="truncate text-xs text-muted">{report.description}</span>
                ) : null}
              </button>
            ))}
          </div>

          {selected ? (
            <ReportDetail
              key={selected.id}
              report={selected}
              locale={locale}
              pt={pt}
              pending={resolve.isPending}
              error={resolve.error instanceof Error ? resolve.error.message : null}
              onResolve={(body) => resolve.mutate({ id: selected.id, body })}
            />
          ) : null}
        </div>
      )}
    </div>
  );
}

function ReportDetail({
  report,
  locale,
  pt,
  pending,
  error,
  onResolve,
}: {
  report: AdminReport;
  locale: string;
  pt: boolean;
  pending: boolean;
  error: string | null;
  onResolve: (body: { status: 'RESOLVED' | 'REJECTED'; note?: string }) => void;
}) {
  const [status, setStatus] = useState<'RESOLVED' | 'REJECTED'>('RESOLVED');
  const [note, setNote] = useState('');
  const pendingReport = report.status === 'PENDING' || report.status === 'REVIEWED';

  return (
    <Surface className="grid content-start gap-4">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="m-0">{report.reason}</h2>
          <p className="m-0 text-sm text-muted">
            {targetOf(report)} · {new Date(report.createdAt).toLocaleString(locale)}
          </p>
        </div>
        <Status tone={tone(report.status)}>{report.status}</Status>
      </header>

      <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 text-sm">
        <dt className="text-muted">{pt ? 'Denunciante' : 'Reporter'}</dt>
        <dd className="m-0">{report.reporter.displayName}</dd>
        <dt className="text-muted">{pt ? 'Denunciado' : 'Reported user'}</dt>
        <dd className="m-0">{report.reportedUser?.displayName ?? '—'}</dd>
        <dt className="text-muted">{pt ? 'Alvo' : 'Target'}</dt>
        <dd className="m-0">{targetOf(report)}</dd>
        <dt className="text-muted">{pt ? 'Descrição' : 'Description'}</dt>
        <dd className="m-0">{report.description ?? '—'}</dd>
      </dl>

      {pendingReport ? (
        <form
          className="grid gap-3 border-t border-(--hairline) pt-4"
          onSubmit={(event) => {
            event.preventDefault();
            onResolve({ status, note: note.trim() || undefined });
          }}
        >
          <h3 className="m-0">{pt ? 'Resolver denúncia' : 'Resolve report'}</h3>
          <label className="grid gap-1.5 text-xs">
            <span>{pt ? 'Decisão' : 'Decision'}</span>
            <select
              className="min-h-[42px] border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink"
              value={status}
              onChange={(event) => setStatus(event.target.value as 'RESOLVED' | 'REJECTED')}
            >
              <option value="RESOLVED">{pt ? 'Procedente' : 'Resolved'}</option>
              <option value="REJECTED">{pt ? 'Improcedente' : 'Rejected'}</option>
            </select>
          </label>
          <label className="grid gap-1.5 text-xs">
            <span>{pt ? 'Nota (opcional)' : 'Note (optional)'}</span>
            <textarea
              className="min-h-24 border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink"
              maxLength={500}
              value={note}
              onChange={(event) => setNote(event.target.value)}
            />
          </label>
          {error ? (
            <p role="alert" className="m-0 text-danger">
              {error}
            </p>
          ) : null}
          <Button type="submit" pending={pending}>
            {pt ? 'Confirmar decisão' : 'Confirm decision'}
          </Button>
        </form>
      ) : null}
    </Surface>
  );
}
