import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// Destination box of the safe-link dialog: host, full URL and copy action.
class SafeLinkDestination extends StatelessWidget {
  const SafeLinkDestination({
    super.key,
    required this.host,
    required this.normalizedUrl,
  });

  final String host;
  final String normalizedUrl;

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: normalizedUrl));
    AppSnackbar.success(context, l10n(context).safeLinkCopied);
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceContainerHighest,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.safeLinkDestination.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            host,
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  normalizedUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () => _copyUrl(context),
                tooltip: strings.safeLinkCopy,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
