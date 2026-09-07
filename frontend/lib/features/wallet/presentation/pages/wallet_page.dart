import 'package:flutter/material.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_refresh_indicator.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/guest_gate_view.dart';
import 'package:freebay/core/components/wallet_card.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/utils/currency_utils.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final wallet = ref.read(walletProvider);
    final history = ref.read(walletHistoryProvider);
    if (wallet.hasValue || wallet.isLoading || history.isLoading) return;

    Future.microtask(() {
      if (!mounted) return;
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        ref.read(walletProvider.notifier).loadWallet();
        ref.read(walletHistoryProvider.notifier).load();
        ref.read(connectStatusProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(authControllerProvider).value;
    final walletState = ref.watch(walletProvider);
    final historyState = ref.watch(walletHistoryProvider);
    final connectState = ref.watch(connectStatusProvider);

    if (user == null) {
      return Scaffold(
        body: GuestGateView(
          icon: Icons.account_balance_wallet_outlined,
          title: 'CARTEIRA & CUSTÓDIA',
          description:
              'Gerencie seu saldo, realize saques instantâneos via PIX e negocie com garantia de custódia protegida.',
          benefits: const [
            '0% de taxa sobre compras e vendas',
            'Saques rápidos via PIX',
            'Custódia segura até a entrega do produto',
          ],
          onLoginPressed: () => context.push(loginPathFrom(context)),
          onRegisterPressed: () => context.push('/register'),
        ),
      );
    }

    final availableBalance = walletState.value?.availableBalance ?? 0;
    final pendingBalance = walletState.value?.pendingBalance ?? 0;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'CARTEIRA',
            actions: [
              IconButton(
                icon: Icon(Icons.help_outline, color: context.textPrimary),
                onPressed: () => context.push('/faq'),
              ),
            ],
          ),
          Expanded(
            child: walletState.isLoading
                ? const SkeletonPage(
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        ShimmerBlock(height: 120),
                        SizedBox(height: 12),
                        ShimmerBlock(height: 60),
                      ],
                    ),
                  )
                : AppRefreshIndicator(
                    onRefresh: () async {
                      ref.read(walletProvider.notifier).loadWallet();
                      ref.read(connectStatusProvider.notifier).load();
                      await ref.read(walletHistoryProvider.notifier).load();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WalletCard(
                            availableBalanceInCents: availableBalance,
                            pendingBalanceInCents: pendingBalance,
                          ),
                          Spacing.vMd,
                          _PayoutSection(
                            status: connectState.value,
                            isLoading: connectState.isLoading,
                            onStartOnboarding: _startOnboarding,
                            onOpenDashboard: _openDashboard,
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
                          if (historyState.transactions.isEmpty)
                            const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'SEM TRANSAÇÕES',
                              subtitle: 'Suas transações aparecerão aqui.',
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: historyState.transactions.length,
                              separatorBuilder: (context, index) => Container(
                                height: 1,
                                color: context.borderColor.withAlpha(30),
                              ),
                              itemBuilder: (context, i) {
                                final tx = historyState.transactions[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    tx.isCredit
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: tx.isCredit
                                        ? AppColors.success
                                        : AppColors.error,
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
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    '${tx.isCredit ? '+' : '-'}${CurrencyUtils.formatCents(tx.amount.abs())}',
                                    style: TextStyle(
                                      color: tx.isCredit
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (historyState.hasMore)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: historyState.isLoadingMore
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : AppButton(
                                      label: 'CARREGAR MAIS',
                                      variant: AppButtonVariant.secondary,
                                      onPressed: () => ref
                                          .read(walletHistoryProvider.notifier)
                                          .loadMore(),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _startOnboarding() async {
    final result = await ref
        .read(walletRepositoryProvider)
        .startConnectOnboarding();
    if (!mounted) return;
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (url) => _openExternal(url),
    );
  }

  Future<void> _openDashboard() async {
    final result = await ref
        .read(walletRepositoryProvider)
        .getConnectDashboardLink();
    if (!mounted) return;
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (url) => _openExternal(url),
    );
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      AppSnackbar.error(context, 'Não foi possível abrir o Stripe.');
      return;
    }
    if (mounted) {
      ref.read(connectStatusProvider.notifier).load();
    }
  }
}

class _PayoutSection extends StatelessWidget {
  const _PayoutSection({
    required this.status,
    required this.isLoading,
    required this.onStartOnboarding,
    required this.onOpenDashboard,
  });

  final ConnectStatusEntity? status;
  final bool isLoading;
  final Future<void> Function() onStartOnboarding;
  final Future<void> Function() onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ShimmerBlock(height: 56);
    }

    final current = status;
    if (current == null || !current.canReceive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current == null || !current.onboarded
                ? 'Cadastre seus dados de recebimento para receber suas vendas.'
                : 'Seu cadastro de recebimentos está em análise pelo Stripe.',
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          Spacing.vSm,
          AppButton(
            label: current == null || !current.onboarded
                ? 'CONFIGURAR RECEBIMENTOS'
                : 'CONTINUAR CADASTRO',
            onPressed: onStartOnboarding,
          ),
        ],
      );
    }

    return AppButton(
      label: 'ABRIR PAINEL DE PAGAMENTOS',
      onPressed: onOpenDashboard,
    );
  }
}
