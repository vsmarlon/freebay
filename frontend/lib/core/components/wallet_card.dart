import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletCard extends StatefulWidget {
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
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool _valuesHidden = false;
  static const _prefKey = 'wallet_values_hidden';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) setState(() => _valuesHidden = prefs.getBool(_prefKey) ?? false);
    });
  }

  void _toggleHidden() {
    final next = !_valuesHidden;
    setState(() => _valuesHidden = next);
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(_prefKey, next));
  }

  String _masked(String value) => _valuesHidden ? 'R\$ •••' : value;

  @override
  Widget build(BuildContext context) {
    if (widget.isMinimized) {
      return _buildMinimized(context);
    }

    final total = CurrencyUtils.formatCents(
      widget.availableBalanceInCents + widget.pendingBalanceInCents,
    );
    final available = CurrencyUtils.formatCents(widget.availableBalanceInCents);
    final pending = CurrencyUtils.formatCents(widget.pendingBalanceInCents);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
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
                  'SALDO TOTAL',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: _toggleHidden,
                  child: Icon(
                    _valuesHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _masked(total),
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem(
                    'DISPONÍVEL',
                    _masked(available),
                    solid: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBalanceItem(
                    'PENDENTE',
                    _masked(pending),
                    solid: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimized(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
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
                    _masked(
                        CurrencyUtils.formatCents(widget.availableBalanceInCents)),
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
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

  Widget _buildBalanceItem(String label, String value, {required bool solid}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: solid ? Colors.white : Colors.white38,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
