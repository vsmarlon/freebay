import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/utils/currency_utils.dart';

class WalletCard extends StatelessWidget {
  final int availableBalanceInCents;
  final int pendingBalanceInCents;
  final bool isMinimized;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.availableBalanceInCents,
    required this.pendingBalanceInCents,
    this.isMinimized = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isMinimized) {
      return _buildMinimized(context, isDark);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.brutalistGradient,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo Total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white.withAlpha(204),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyUtils.formatCents(availableBalanceInCents + pendingBalanceInCents),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem(
                    'Disponível',
                    CurrencyUtils.formatCents(availableBalanceInCents),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBalanceItem(
                    'Pendente',
                    CurrencyUtils.formatCents(pendingBalanceInCents),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimized(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withAlpha(25),
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.accentGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saldo', style: AppTypography.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyUtils.formatCents(availableBalanceInCents),
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.mediumGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
