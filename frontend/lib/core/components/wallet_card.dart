import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';

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

  String _formatCurrency(int cents) {
    return (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
  }

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
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.primaryPurpleDark, AppColors.primaryPurple]
                : [AppColors.primaryPurple, AppColors.primaryPurpleLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withAlpha(76),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
                  Icons.account_balance_wallet,
                  color: Colors.white.withAlpha(204),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'R\$ ${_formatCurrency(availableBalanceInCents + pendingBalanceInCents)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem(
                    'Disponível',
                    'R\$ ${_formatCurrency(availableBalanceInCents)}',
                    isDark: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ),
                Expanded(
                  child: _buildBalanceItem(
                    'Pendente',
                    'R\$ ${_formatCurrency(pendingBalanceInCents)}',
                    isDark: true,
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? AppColors.black.withAlpha(51)
                  : AppColors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppColors.accentGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppColors.mediumGray : AppColors.mediumGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'R\$ ${_formatCurrency(availableBalanceInCents)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, {required bool isDark}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
