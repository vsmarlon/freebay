import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/wallet_card.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    final user = authState.valueOrNull;
    if (user != null && !user.isGuest) {
      ref.read(walletProvider.notifier).loadWallet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final authState = ref.watch(authControllerProvider);
    final walletState = ref.watch(walletProvider);
    final user = authState.valueOrNull;
    final isGuest = user == null || user.isGuest;

    final availableBalance = walletState.valueOrNull?.availableBalance ?? 0;
    final pendingBalance = walletState.valueOrNull?.pendingBalance ?? 0;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'CARTEIRA',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.help_outline,
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
                onPressed: () => context.push('/faq'),
              ),
            ],
          ),
          Expanded(
            child: walletState.isLoading && !isGuest
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
                        Spacing.vMd,
                        Text(
                          'Não foi possível carregar o saldo.',
                          style: TextStyle(
                            fontFamily: AppTypography.headlineFontFamily,
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
                  Spacing.vLg,
                  Text(
                    'Visão da carteira',
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
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
                        ),
                        Spacing.vMd,
                        _buildInfoLine(
                          label: 'Em custódia',
                          value: 'Valor aguardando confirmação do pedido.',
                        ),
                        Spacing.vMd,
                        _buildInfoLine(
                          label: 'Saques',
                          value: 'Saques automáticos ficam para a próxima etapa do produto.',
                        ),
                      ],
                    ),
                  ),
                  Spacing.vLg,
                  Text(
                    'Histórico',
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isGuest)
                    _buildEmptyState(context)
                  else
                    _buildEmptyState(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'SEM TRANSAÇÕES',
      subtitle: 'Realize uma compra ou venda para visualizar suas transações aqui.',
    );
  }

  Widget _buildInfoLine({
    required String label,
    required String value,
  }) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
          ),
        ),
      ],
    );
  }
}
