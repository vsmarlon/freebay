import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class WalletHistoryList extends StatelessWidget {
  const WalletHistoryList({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onLoadMore,
  });

  final WalletHistoryState state;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    if (state.error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.errorUnknown,
            style: TextStyle(color: context.textSecondary),
          ),
          Spacing.vSm,
          AppButton(
            label: strings.commonRetry.toUpperCase(),
            variant: AppButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      );
    }
    if (state.transactions.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: strings.walletEmptyTransactions,
        subtitle: strings.walletTransactionsEmpty,
      );
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.transactions.length,
          separatorBuilder: (context, index) =>
              Container(height: 1, color: context.borderColor.withAlpha(30)),
          itemBuilder: (context, i) {
            final tx = state.transactions[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: tx.isCredit ? AppColors.success : AppColors.error,
              ),
              title: Text(
                tx.label,
                style: TextStyle(
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                style: TextStyle(color: context.textSecondary, fontSize: 12),
              ),
              trailing: Text(
                '${tx.isCredit ? '+' : '-'}${CurrencyUtils.formatCents(tx.amount.abs())}',
                style: TextStyle(
                  color: tx.isCredit ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            );
          },
        ),
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: state.isLoadingMore
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : AppButton(
                    label: strings.profileLoadMore,
                    variant: AppButtonVariant.secondary,
                    onPressed: onLoadMore,
                  ),
          ),
      ],
    );
  }
}
