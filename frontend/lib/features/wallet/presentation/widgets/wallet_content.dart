import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart'
    hide ConnectStatus;
import 'package:freebay/features/wallet/presentation/widgets/wallet_history.dart';
import 'package:freebay/features/wallet/presentation/widgets/wallet_balance.dart';
import 'package:freebay/features/wallet/presentation/widgets/wallet_payout_section.dart';

class WalletContent extends StatelessWidget {
  const WalletContent({
    super.key,
    required this.availableBalance,
    required this.pendingBalance,
    required this.connectStatus,
    required this.connectLoading,
    required this.historyState,
    required this.onStartOnboarding,
    required this.onOpenDashboard,
    required this.onRetryHistory,
    required this.onLoadMore,
  });

  final int availableBalance;
  final int pendingBalance;
  final ConnectStatusEntity? connectStatus;
  final bool connectLoading;
  final WalletHistoryState historyState;
  final Future<void> Function() onStartOnboarding;
  final Future<void> Function() onOpenDashboard;
  final VoidCallback onRetryHistory;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WalletBalance(
          availableBalance: availableBalance,
          pendingBalance: pendingBalance,
        ),
        Spacing.vMd,
        WalletPayoutSection(
          status: connectStatus,
          isLoading: connectLoading,
          onStartOnboarding: onStartOnboarding,
          onOpenDashboard: onOpenDashboard,
        ),
        Spacing.vLg,
        Text(
          'TRANSAÇÕES RECENTES',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: context.textSecondary,
          ),
        ),
        Spacing.vSm,
        WalletHistoryList(
          state: historyState,
          onRetry: onRetryHistory,
          onLoadMore: onLoadMore,
        ),
      ],
    );
  }
}
