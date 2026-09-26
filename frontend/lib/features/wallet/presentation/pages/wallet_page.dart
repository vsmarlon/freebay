import 'package:flutter/material.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart'
    hide ConnectStatus;
import 'package:freebay/features/wallet/presentation/widgets/wallet_content.dart';
import 'package:freebay/features/wallet/presentation/widgets/wallet_error_states.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final authState = ref.watch(authControllerProvider);
    final walletState = ref.watch(walletProvider);
    final historyState = ref.watch(walletHistoryProvider);
    final connectState = ref.watch(connectStatusProvider);

    ref.listen<AsyncValue<UserEntity?>>(
      authControllerProvider,
      (_, next) => _syncWalletSession(next),
    );

    // Auth still loading — show skeleton, not guest view
    if (authState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            PageHeader(text: 'CARTEIRA'),
            Expanded(
              child: SkeletonPage(
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    ShimmerBlock(height: 120),
                    SizedBox(height: 12),
                    ShimmerBlock(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final user = authState.value;

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
                ? WalletErrorState(
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
                      child: WalletContent(
                        availableBalance: availableBalance,
                        pendingBalance: pendingBalance,
                        connectStatus: connectState.value,
                        connectLoading: connectState.isLoading,
                        historyState: historyState,
                        onStartOnboarding: _startOnboarding,
                        onOpenDashboard: _openDashboard,
                        onRetryHistory: () => ref
                            .read(walletHistoryProvider.notifier)
                            .load(user.id),
                        onLoadMore: () =>
                            ref.read(walletHistoryProvider.notifier).loadMore(),
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
      if (user != null) ref.read(connectStatusProvider.notifier).load(user.id);
    }
  }
}
