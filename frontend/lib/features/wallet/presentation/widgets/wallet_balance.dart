import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class WalletBalance extends StatelessWidget {
  const WalletBalance({
    super.key,
    required this.availableBalance,
    required this.pendingBalance,
  });

  final int availableBalance;
  final int pendingBalance;

  @override
  Widget build(BuildContext context) {
    return WalletCard(
      availableBalanceInCents: availableBalance,
      pendingBalanceInCents: pendingBalance,
    );
  }
}
