import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/wallet_card.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authControllerProvider);
      final user = authState.valueOrNull;
      if (user != null && !user.isGuest) {
        ref.read(walletProvider.notifier).loadWallet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final walletState = ref.watch(walletProvider);
    final user = authState.valueOrNull;
    final isGuest = user == null || user.isGuest;

    final availableBalance = walletState.valueOrNull?.availableBalance ?? 0;
    final pendingBalance = walletState.valueOrNull?.pendingBalance ?? 0;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Carteira',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: walletState.isLoading && !isGuest
          ? const Center(child: CircularProgressIndicator())
          : walletState.hasError && !isGuest
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Não foi possível carregar o saldo.',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.white : AppColors.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WalletCard(
                    availableBalanceInCents: availableBalance,
                    pendingBalanceInCents: pendingBalance,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Visão da carteira',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoLine(
                          label: 'Disponível',
                          value: 'Saldo já liberado para o vendedor.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoLine(
                          label: 'Em custódia',
                          value: 'Valor aguardando confirmação do pedido.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoLine(
                          label: 'Saques',
                          value: 'Saques automáticos ficam para a próxima etapa do produto.',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Histórico',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isGuest)
                    _buildEmptyState(context, isDark)
                  else
                    _buildEmptyState(context, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
          ),
          const SizedBox(height: 16),
          Text(
            'Sem transações',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Realize uma compra ou venda para visualizar suas transações aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
          ),
        ),
      ],
    );
  }
}
