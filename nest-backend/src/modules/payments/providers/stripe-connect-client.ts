import { Logger } from '@nestjs/common';
import Stripe from 'stripe';
import { Either, left, right } from '@/shared/core/either';
import { AppError, PaymentProviderError } from '@/shared/core/errors';
import {
  ConnectAccountSnapshot,
  ConnectStatus,
  CreateConnectAccountParams,
  CreateTransferParams,
  ReversalReconciliationParams,
  TransferReconciliationParams,
  TransferReconciliationResult,
} from '../types/connect.types';

export class StripeConnectClient {
  constructor(
    private readonly stripe: Stripe,
    private readonly logger: Logger,
  ) {}

  async createAccount(
    params: CreateConnectAccountParams,
  ): Promise<Either<AppError, ConnectAccountSnapshot>> {
    try {
      const account = await this.stripe.v2.core.accounts.create({
        contact_email: params.email,
        display_name: params.displayName,
        dashboard: 'express',
        identity: { country: params.country },
        defaults: {
          currency: params.currency,
          responsibilities: {
            fees_collector: 'application',
            losses_collector: 'application',
          },
        },
        configuration: {
          recipient: {
            capabilities: { stripe_balance: { stripe_transfers: { requested: true } } },
          },
        },
        include: ['configuration.recipient', 'identity', 'requirements', 'future_requirements'],
      });

      return right(this.toSnapshot(account, params.country, params.currency));
    } catch (error) {
      return left(this.error('Connect account creation', error));
    }
  }

  async refreshAccount(
    stripeAccountId: string,
  ): Promise<Either<AppError, ConnectAccountSnapshot>> {
    try {
      const account = await this.stripe.v2.core.accounts.retrieve(stripeAccountId, {
        include: ['configuration.recipient', 'identity', 'requirements', 'future_requirements'],
      });
      return right(this.toSnapshot(account, '', ''));
    } catch (error) {
      return left(this.error('Connect account refresh', error));
    }
  }

  async createOnboardingLink(
    stripeAccountId: string,
    refreshUrl: string,
    returnUrl: string,
  ): Promise<Either<AppError, string>> {
    try {
      const link = await this.stripe.v2.core.accountLinks.create({
        account: stripeAccountId,
        use_case: {
          type: 'account_onboarding',
          account_onboarding: {
            configurations: ['recipient'],
            refresh_url: refreshUrl,
            return_url: returnUrl,
          },
        },
      });
      return right(link.url);
    } catch (error) {
      return left(this.error('Connect onboarding link', error));
    }
  }

  async createDashboardLink(stripeAccountId: string): Promise<Either<AppError, string>> {
    try {
      const link = await this.stripe.accounts.createLoginLink(stripeAccountId);
      return right(link.url);
    } catch (error) {
      return left(this.error('Connect dashboard link', error));
    }
  }

  async createTransfer(params: CreateTransferParams): Promise<Either<AppError, string>> {
    try {
      const transfer = await this.stripe.transfers.create(
        {
          amount: params.amount,
          currency: params.currency,
          destination: params.destination,
          source_transaction: params.sourceTransaction,
          transfer_group: params.transferGroup,
          metadata: {
            orderId: params.orderId,
            transactionId: params.transactionId,
            ...(params.paymentGroupId ? { paymentGroupId: params.paymentGroupId } : {}),
            idempotencyKey: params.idempotencyKey,
          },
        },
        { idempotencyKey: params.idempotencyKey },
      );
      return right(transfer.id);
    } catch (error) {
      return left(this.error('Transfer creation', error));
    }
  }

  async reverseTransfer(
    transferId: string,
    amount: number,
    orderId: string,
    transactionId: string,
    idempotencyKey: string,
  ): Promise<Either<AppError, string>> {
    try {
      const reversal = await this.stripe.transfers.createReversal(
        transferId,
        { amount, metadata: { orderId, transactionId, idempotencyKey } },
        { idempotencyKey },
      );
      return right(reversal.id);
    } catch (error) {
      return left(this.error('Transfer reversal', error));
    }
  }

  async findTransfer(
    params: TransferReconciliationParams,
  ): Promise<Either<AppError, TransferReconciliationResult | null>> {
    try {
      if (params.transferId) {
        const transfer = await this.stripe.transfers.retrieve(params.transferId);
        return right(this.matchesTransfer(transfer, params) ? { providerId: transfer.id } : null);
      }

      const transfers = await this.stripe.transfers.list({
        transfer_group: params.transferGroup,
        limit: 100,
      });
      const match = transfers.data.find((transfer) => this.matchesTransfer(transfer, params));
      return right(match ? { providerId: match.id } : null);
    } catch (error) {
      return left(this.error('Transfer reconciliation', error));
    }
  }

  async findReversal(
    params: ReversalReconciliationParams,
  ): Promise<Either<AppError, string | null>> {
    try {
      if (!params.reversalId) return right(null);
      const reversal = await this.stripe.transfers.retrieveReversal(
        params.transferId,
        params.reversalId,
      );
      const metadata = reversal.metadata ?? {};
      return right(
        metadata.orderId === params.orderId &&
          metadata.transactionId === params.transactionId &&
          metadata.idempotencyKey === params.idempotencyKey
          ? reversal.id
          : null,
      );
    } catch (error) {
      return left(this.error('Reversal reconciliation', error));
    }
  }

  private matchesTransfer(
    transfer: Stripe.Transfer,
    params: TransferReconciliationParams,
  ): boolean {
    return (
      transfer.destination === params.destination &&
      transfer.transfer_group === params.transferGroup &&
      transfer.metadata.orderId === params.orderId &&
      transfer.metadata.transactionId === params.transactionId &&
      transfer.metadata.idempotencyKey === params.idempotencyKey &&
      (!params.paymentGroupId || transfer.metadata.paymentGroupId === params.paymentGroupId)
    );
  }

  private toSnapshot(
    account: Stripe.V2.Core.Account,
    fallbackCountry: string,
    fallbackCurrency: string,
  ): ConnectAccountSnapshot {
    const balance = account.configuration?.recipient?.capabilities?.stripe_balance;
    const requirements = account.requirements?.entries ?? [];
    const transferStatus = balance?.stripe_transfers?.status;
    const hasDueRequirements = requirements.some(
      (entry) =>
        entry.minimum_deadline.status === 'currently_due' ||
        entry.minimum_deadline.status === 'past_due',
    );
    const hasRecipient =
      account.configuration?.recipient !== undefined &&
      account.applied_configurations.includes('recipient');
    let status: ConnectStatus = 'onboarding-required';
    if (account.closed || transferStatus === 'restricted' || transferStatus === 'unsupported') {
      status = 'restricted';
    } else if (!hasRecipient) {
      status = 'onboarding-required';
    } else if (transferStatus === 'active') {
      status = 'transfer-ready';
    } else if (transferStatus === 'pending' && hasDueRequirements) {
      status = 'requirements-due';
    }

    return {
      stripeAccountId: account.id,
      country: account.identity?.country ?? fallbackCountry,
      defaultCurrency: account.defaults?.currency ?? fallbackCurrency,
      status,
      transfersEnabled: balance?.stripe_transfers?.status === 'active',
      payoutsEnabled: balance?.payouts?.status === 'active',
      detailsSubmitted: hasRecipient,
      requirementsDue: requirements
        .filter(
          (entry) =>
            entry.minimum_deadline.status === 'currently_due' ||
            entry.minimum_deadline.status === 'past_due',
        )
        .map((entry) => entry.description),
    };
  }

  private error(operation: string, error: unknown): AppError {
    const message = error instanceof Error ? error.message : 'Unknown error';
    this.logger.error(`${operation} failed: ${message}`);
    const statusCode = error instanceof Stripe.errors.StripeError ? error.statusCode ?? 500 : 500;
    return new PaymentProviderError('Erro na integração de pagamentos', statusCode);
  }
}
