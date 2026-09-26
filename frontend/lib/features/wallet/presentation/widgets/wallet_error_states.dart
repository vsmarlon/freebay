import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class WalletErrorState extends StatelessWidget {
  const WalletErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

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

class WalletHistoryError extends StatelessWidget {
  const WalletHistoryError({
    super.key,
    required this.message,
    required this.onRetry,
  });

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
