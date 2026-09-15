import 'package:flutter/material.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart'
    hide ConnectStatus;
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

  String? _walletUserId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _syncWalletSession(ref.read(authControllerProvider));
    });
  }

  void _syncWalletSession(AsyncValue<UserEntity?> next) {
    final user = next.value;
    if (user == null) {
      if (next.hasValue && _walletUserId != null) {
        _walletUserId = null;
        ref.read(walletProvider.notifier).reset();
        ref.read(walletHistoryProvider.notifier).reset();
        ref.read(connectStatusProvider.notifier).reset();
      }
      return;
    }
    if (_walletUserId == user.id) return;
    _walletUserId = user.id;
    ref.read(walletProvider.notifier).loadWallet(user.id);
    ref.read(walletHistoryProvider.notifier).load(user.id);
    ref.read(connectStatusProvider.notifier).load(user.id);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(authControllerProvider).value;
    final walletState = ref.watch(walletProvider);
    final historyState = ref.watch(walletHistoryProvider);
    final connectState = ref.watch(connectStatusProvider);

    ref.listen<AsyncValue<UserEntity?>>(
      authControllerProvider,
      (_, next) => _syncWalletSession(next),
    );

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const PageHeader(text: 'CARTEIRA'),
            Expanded(
              child: GuestGateView(
                icon: Icons.account_balance_wallet_outlined,
                title: 'CARTEIRA',
                description:
                    'Acompanhe seu saldo e configure seus recebimentos.',
                onLoginPressed: () => context.push(loginPathFrom(context)),
                onRegisterPressed: () => context.push(AppRoutes.register),
              ),
            ),
          ],
        ),
      );
    }

    final availableBalance = walletState.value?.availableBalance ?? 0;
    final pendingBalance = walletState.value?.pendingBalance ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            text: 'CARTEIRA',
            actions: [
              IconButton(
                icon: Icon(Icons.help_outline, color: context.textPrimary),
                onPressed: () => context.push(AppRoutes.faq),
              ),
            ],
          ),
          Expanded(
            child: walletState.hasError
                ? _WalletErrorState(
                    message: walletState.error.toString(),
                    onRetry: () => _loadWallet(user.id),
                  )
                : walletState.isLoading
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
                      final currentUser = ref
                          .read(authControllerProvider)
                          .value;
                      if (currentUser == null) return;
                      ref
                          .read(walletProvider.notifier)
                          .loadWallet(currentUser.id);
                      ref
                          .read(connectStatusProvider.notifier)
                          .load(currentUser.id);
                      await ref
                          .read(walletHistoryProvider.notifier)
                          .load(currentUser.id);
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
                          if (historyState.error != null)
                            _WalletHistoryError(
                              message: historyState.error!,
                              onRetry: () => ref
                                  .read(walletHistoryProvider.notifier)
                                  .load(user.id),
                            )
                          else if (historyState.transactions.isEmpty)
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

  void _loadWallet(String userId) {
    ref.read(walletProvider.notifier).loadWallet(userId);
    ref.read(walletHistoryProvider.notifier).load(userId);
    ref.read(connectStatusProvider.notifier).load(userId);
  }

  Future<void> _startOnboarding() async {
    final result = await ref
        .read(walletRepositoryProvider)
        .startConnectOnboarding();
    if (!mounted) return;
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      _openExternal,
    );
  }

  Future<void> _openDashboard() async {
    final result = await ref
        .read(walletRepositoryProvider)
        .getConnectDashboardLink();
    if (!mounted) return;
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      _openExternal,
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
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        ref.read(connectStatusProvider.notifier).load(user.id);
      }
    }
  }
}

class _WalletErrorState extends StatelessWidget {
  const _WalletErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            Spacing.vMd,
            AppButton(label: 'TENTAR NOVAMENTE', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _WalletHistoryError extends StatelessWidget {
  const _WalletHistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(color: context.textSecondary)),
        Spacing.vSm,
        AppButton(
          label: 'TENTAR NOVAMENTE',
          variant: AppButtonVariant.secondary,
          onPressed: onRetry,
        ),
      ],
    );
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
    final effectiveStatus = current?.status ?? ConnectStatus.onboardingRequired;
    final onboarding = effectiveStatus == ConnectStatus.onboardingRequired;
    final copy = switch (effectiveStatus) {
      ConnectStatus.onboardingRequired =>
        'Cadastre seus dados de recebimento para receber suas vendas.',
      ConnectStatus.requirementsDue =>
        'Há informações pendentes para liberar o recebimento das vendas.',
      ConnectStatus.restricted =>
        'O Stripe restringiu seus recebimentos. Abra o painel para corrigir o cadastro.',
      ConnectStatus.transferReady =>
        'Recebimentos habilitados. O saldo permanece na carteira até a transferência.',
    };
    final action = onboarding ? onStartOnboarding : onOpenDashboard;
    final label = onboarding
        ? 'CONFIGURAR RECEBIMENTOS'
        : effectiveStatus == ConnectStatus.transferReady
        ? 'ABRIR PAINEL DE PAGAMENTOS'
        : 'CORRIGIR CADASTRO NO STRIPE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy,
          style: TextStyle(fontSize: 13, color: context.textSecondary),
        ),
        if (current?.requirementsDue.isNotEmpty ?? false) ...[
          Spacing.vSm,
          Text(
            'PENDÊNCIAS: ${current!.requirementsDue.join(', ')}',
            style: TextStyle(fontSize: 12, color: context.textSecondary),
          ),
        ],
        Spacing.vSm,
        AppButton(label: label, onPressed: action),
      ],
    );
  }
}
