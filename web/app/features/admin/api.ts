import { api } from '../../core/api';
import type {
  AdminDispute,
  AdminReport,
  DisputeStatus,
  DisputeWinner,
  ReportStatus,
} from './types';

const disputeQuery = (status?: string) => {
  const params = new URLSearchParams({ limit: '100' });
  if (status && status !== 'ALL') params.set('status', status);
  return params.toString();
};

export const adminApi = {
  disputes: (status: string | undefined, signal?: AbortSignal) =>
    api.get<{ disputes: AdminDispute[] }>(`/admin/disputes?${disputeQuery(status)}`, { signal }),
  resolveDispute: (id: string, body: { resolution: string; winner: DisputeWinner }) =>
    api.patch(`/disputes/${encodeURIComponent(id)}/resolve`, body, { retryAfterRefresh: false }),
  reports: (status: ReportStatus | undefined, signal?: AbortSignal) => {
    const params = new URLSearchParams({ limit: '100' });
    if (status) params.set('status', status);
    return api.get<{ items: AdminReport[]; nextCursor: string | null }>(
      `/admin/reports?${params}`,
      { signal },
    );
  },
  resolveReport: (id: string, body: { status: Exclude<ReportStatus, 'PENDING'>; note?: string }) =>
    api.patch(`/admin/reports/${encodeURIComponent(id)}/resolve`, body, {
      retryAfterRefresh: false,
    }),
};

export const disputeStatusLabel: Record<DisputeStatus | 'ALL', { pt: string; en: string }> = {
  ALL: { pt: 'Todas', en: 'All' },
  OPEN: { pt: 'Aberta', en: 'Open' },
  AWAITING_SELLER: { pt: 'Aguardando vendedor', en: 'Awaiting seller' },
  AWAITING_BUYER: { pt: 'Aguardando comprador', en: 'Awaiting buyer' },
  ESCALATED: { pt: 'Em análise', en: 'Escalated' },
  RESOLVED: { pt: 'Resolvida', en: 'Resolved' },
  CANCELLED: { pt: 'Cancelada', en: 'Cancelled' },
};

export const isActiveDispute = (status: DisputeStatus) =>
  status === 'OPEN' ||
  status === 'AWAITING_SELLER' ||
  status === 'AWAITING_BUYER' ||
  status === 'ESCALATED';

export const money = (cents: number, locale: string) =>
  new Intl.NumberFormat(locale, { style: 'currency', currency: 'BRL' }).format(cents / 100);
