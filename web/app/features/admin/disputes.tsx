import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { Button, Empty, ErrorState, Loading, Status, Surface } from '../../components';
import { useI18n } from '../../core/locale';
import { adminApi, disputeStatusLabel, isActiveDispute, money } from './api';
import type { AdminDispute, DisputeStatus, DisputeWinner } from './types';

const FILTERS: Array<DisputeStatus | 'ALL'> = [
  'ESCALATED',
  'OPEN',
  'AWAITING_SELLER',
  'AWAITING_BUYER',
  'RESOLVED',
  'CANCELLED',
  'ALL',
];

const tone = (status: DisputeStatus) =>
  status === 'RESOLVED'
    ? 'success'
    : status === 'CANCELLED'
      ? 'neutral'
      : status === 'ESCALATED'
        ? 'warning'
        : 'info';

const evidence = (value: unknown) =>
  value == null ? '—' : typeof value === 'string' ? value : JSON.stringify(value, null, 2);

export default function AdminDisputesPage() {
  const { locale } = useI18n();
  const pt = locale === 'pt-BR';
  const [filter, setFilter] = useState<DisputeStatus | 'ALL'>('ESCALATED');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['admin', 'disputes', filter],
    queryFn: ({ signal }) => adminApi.disputes(filter, signal),
  });

  const disputes = query.data?.disputes ?? [];
  const selected = disputes.find((dispute) => dispute.id === selectedId) ?? disputes[0] ?? null;

  const resolve = useMutation({
    mutationFn: ({
      id,
      body,
    }: {
      id: string;
      body: { resolution: string; winner: DisputeWinner };
    }) => adminApi.resolveDispute(id, body),
    onSuccess: () => void queryClient.invalidateQueries({ queryKey: ['admin', 'disputes'] }),
  });

  if (query.isPending) return <Loading label={pt ? 'Carregando disputas…' : 'Loading disputes…'} />;
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
              setFilter(event.target.value as DisputeStatus | 'ALL');
              setSelectedId(null);
            }}
          >
            {FILTERS.map((status) => (
              <option key={status} value={status}>
                {pt ? disputeStatusLabel[status].pt : disputeStatusLabel[status].en}
              </option>
            ))}
          </select>
        </label>
        <p className="m-0 text-sm text-muted">
          {pt ? `${disputes.length} disputa(s)` : `${disputes.length} dispute(s)`}
        </p>
      </div>

      {disputes.length === 0 ? (
        <Empty
          title={pt ? 'Fila vazia' : 'Queue empty'}
          description={pt ? 'Nenhuma disputa neste status.' : 'No disputes with this status.'}
        />
      ) : (
        <div className="grid gap-4 lg:grid-cols-[minmax(260px,380px)_minmax(0,1fr)]">
          <div className="grid content-start gap-2">
            {disputes.map((dispute) => (
              <button
                key={dispute.id}
                type="button"
                onClick={() => setSelectedId(dispute.id)}
                className={`grid cursor-pointer gap-1.5 border p-3 text-left ${
                  selected?.id === dispute.id
                    ? 'border-brand bg-surface-high'
                    : 'border-(--hairline) bg-surface hover:bg-surface-mid'
                }`}
              >
                <strong className="truncate">{dispute.order.product.title}</strong>
                <Status tone={tone(dispute.status)}>
                  {pt
                    ? disputeStatusLabel[dispute.status].pt
                    : disputeStatusLabel[dispute.status].en}
                </Status>
                <small className="text-muted">
                  {new Date(dispute.createdAt).toLocaleString(locale)}
                </small>
                <span className="truncate text-xs text-muted">{dispute.reason}</span>
              </button>
            ))}
          </div>

          {selected ? (
            <DisputeDetail
              key={selected.id}
              dispute={selected}
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

function DisputeDetail({
  dispute,
  locale,
  pt,
  pending,
  error,
  onResolve,
}: {
  dispute: AdminDispute;
  locale: string;
  pt: boolean;
  pending: boolean;
  error: string | null;
  onResolve: (body: { resolution: string; winner: DisputeWinner }) => void;
}) {
  const [winner, setWinner] = useState<DisputeWinner>('BUYER');
  const [resolution, setResolution] = useState('');
  const active = isActiveDispute(dispute.status);

  return (
    <Surface className="grid content-start gap-4">
      <header className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="m-0">{dispute.order.product.title}</h2>
          <p className="m-0 text-sm text-muted">
            {pt ? 'Pedido' : 'Order'} {dispute.orderId.slice(0, 8)} ·{' '}
            {money(dispute.order.amount, locale)}
          </p>
        </div>
        <Status tone={tone(dispute.status)}>
          {pt ? disputeStatusLabel[dispute.status].pt : disputeStatusLabel[dispute.status].en}
        </Status>
      </header>

      <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 text-sm">
        <dt className="text-muted">{pt ? 'Motivo' : 'Reason'}</dt>
        <dd className="m-0">{dispute.reason}</dd>
        <dt className="text-muted">{pt ? 'Aberta por' : 'Opened by'}</dt>
        <dd className="m-0">{dispute.openedBy.displayName}</dd>
        <dt className="text-muted">{pt ? 'Comprador' : 'Buyer'}</dt>
        <dd className="m-0">{dispute.order.buyer.displayName}</dd>
        <dt className="text-muted">{pt ? 'Vendedor' : 'Seller'}</dt>
        <dd className="m-0">{dispute.order.seller.displayName}</dd>
        <dt className="text-muted">{pt ? 'Prazo de análise' : 'Review deadline'}</dt>
        <dd className="m-0">{new Date(dispute.expiresAt).toLocaleString(locale)}</dd>
        {dispute.resolvedAt ? (
          <>
            <dt className="text-muted">{pt ? 'Resolvida em' : 'Resolved at'}</dt>
            <dd className="m-0">{new Date(dispute.resolvedAt).toLocaleString(locale)}</dd>
          </>
        ) : null}
        {dispute.winner ? (
          <>
            <dt className="text-muted">{pt ? 'Resultado' : 'Outcome'}</dt>
            <dd className="m-0">
              {dispute.winner === 'BUYER'
                ? pt
                  ? 'Comprador'
                  : 'Buyer'
                : pt
                  ? 'Vendedor'
                  : 'Seller'}
            </dd>
          </>
        ) : null}
      </dl>

      <div className="grid gap-2 md:grid-cols-2">
        <EvidenceBlock
          title={pt ? 'Evidência do comprador' : 'Buyer evidence'}
          value={dispute.buyerEvidence}
        />
        <EvidenceBlock
          title={pt ? 'Evidência do vendedor' : 'Seller evidence'}
          value={dispute.sellerEvidence}
        />
      </div>

      {active ? (
        <form
          className="grid gap-3 border-t border-(--hairline) pt-4"
          onSubmit={(event) => {
            event.preventDefault();
            onResolve({ resolution, winner });
          }}
        >
          <h3 className="m-0">{pt ? 'Resolver disputa' : 'Resolve dispute'}</h3>
          <label className="grid gap-1.5 text-xs">
            <span>{pt ? 'Resultado' : 'Outcome'}</span>
            <select
              className="min-h-[42px] border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink"
              value={winner}
              onChange={(event) => setWinner(event.target.value as DisputeWinner)}
            >
              <option value="BUYER">
                {pt ? 'A favor do comprador (reembolso)' : 'Buyer wins (refund)'}
              </option>
              <option value="SELLER">
                {pt ? 'A favor do vendedor (liberar)' : 'Seller wins (release)'}
              </option>
            </select>
          </label>
          <label className="grid gap-1.5 text-xs">
            <span>{pt ? 'Nota da decisão' : 'Decision note'}</span>
            <textarea
              className="min-h-24 border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink"
              required
              minLength={1}
              maxLength={500}
              value={resolution}
              onChange={(event) => setResolution(event.target.value)}
            />
          </label>
          {error ? (
            <p role="alert" className="m-0 text-danger">
              {error}
            </p>
          ) : null}
          <Button type="submit" pending={pending} disabled={!resolution.trim()}>
            {pt ? 'Confirmar decisão' : 'Confirm decision'}
          </Button>
        </form>
      ) : dispute.resolution ? (
        <p className="m-0 border-t border-(--hairline) pt-4 text-sm">
          <strong>{pt ? 'Decisão: ' : 'Decision: '}</strong>
          {dispute.resolution}
        </p>
      ) : null}
    </Surface>
  );
}

function EvidenceBlock({ title, value }: { title: string; value: unknown }) {
  return (
    <div className="grid gap-1.5">
      <strong className="text-xs">{title}</strong>
      <pre className="m-0 max-h-56 overflow-auto bg-surface-mid p-3 text-xs whitespace-pre-wrap">
        {evidence(value)}
      </pre>
    </div>
  );
}
