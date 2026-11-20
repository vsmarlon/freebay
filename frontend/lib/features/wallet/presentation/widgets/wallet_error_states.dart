import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

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
    final strings = l10n(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            Spacing.vMd,
            AppButton(
              label: strings.commonRetry.toUpperCase(),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
